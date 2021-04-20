import gdvm.device.*
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import mibtool.snmp4jWrapper.*
import java.util.*


@Serializable
data class DeviceAgentMfpMib(
    val time: Long = Date().time,
    val id: String,
    val cluster: String,
    val dev: DeviceDev,
)

// device/{}/query/{query}
@Serializable
data class DeviceAgentMfpMib_QueryDiscovery(
    val time: Long,
    val id: String,
    val devId: String,
    val cluster: String,

    val scanAddrSpecs: List<SnmpTarget> = listOf(),
    val autoRegistration: Boolean = false,
    val schedule: Schedule = Schedule(1),
)

@Serializable
data class DeviceAgentMfpMib_ResultDiscovery(
    val time: Long = Date().time,
    val devId: String,
    val cluster: String,
    val type: List<String> = listOf("log", "log.dev", "log.dev.agent", "log.dev.agent.mfp", "log.dev.agent.mfp.snmp"),
    val attr: Map<String, JsonElement> = mapOf(
        "log" to JsonObject(mapOf("dev" to JsonObject(mapOf()))),
        "dev" to JsonObject(mapOf())
    ),

    val detected: List<String>,
)

@ExperimentalCoroutinesApi
suspend fun runAgent(devAgentId: String, secret: String) = coroutineScope {
    val dev = db.document("device/$devAgentId").get().get().data?.toJsonObject()?.toObject<DeviceAgentMfpMib>()!!
    println("Start deviceId: $devAgentId")
    db.collection("device/$devAgentId/query")
        .whereEqualTo("cluster", "AgentStressTest").limit(3)
        .snapshotsAs<DeviceAgentMfpMib_QueryDiscovery>().collectLatest { queries ->
            queries.forEachIndexed { i, query ->
                println("Updated query $i: $query")//TODO
                launch {
                    scheduleFlow(query.schedule).collect {
                        launch { runAgentQuery(dev, query) }
                    }
                }
            }
        }
}

@ExperimentalCoroutinesApi
suspend fun scheduleFlow(schedule: Schedule) = channelFlow {
    repeat(schedule.limit) { i ->
        offer(i)
        delay(schedule.interval) //TODO 不正確 要対応
    }
}

@ExperimentalCoroutinesApi
suspend fun runAgentQuery(devAg: DeviceAgentMfpMib, query: DeviceAgentMfpMib_QueryDiscovery) {
    println("Start Query: device/${query.devId}/${query.id}")//TODO
    val reqOids = listOf(hrDeviceDescr, prtGeneralSerialNumber)
    val res = query.scanAddrSpecs.asFlow().discoveryDeviceMap(snmp, reqOids).map { res ->
        println("Res: ${res.peerAddress}")// TODO
        val model = res.response.variableBindings[0].variable.toString()
        val sn = res.response.variableBindings[1].variable.toString()
        val devId = "type=dev.mfp.snmp:model=$model:sn=$sn"
        if (query.autoRegistration) {
            createDevice(devId, devAg)
            runMfpSnmp(devId, secretDefault, res.peerAddress.inetAddress.toString())
        }
        devId
    }.toList()
    sendReport(devAg, query.id, res)
    println("Terminate Query: device/${query.devId}/${query.id}")//TODO
}

fun sendReport(devAg: DeviceAgentMfpMib, queryId: String, result: List<String>) {
    val discoveryResult =
        DeviceAgentMfpMib_ResultDiscovery(devId = devAg.id, cluster = devAg.cluster, detected = result)
    db.collection("device/${devAg.id}/logs").document().set(discoveryResult)
    db.document("device/${devAg.id}/state/$queryId").set(discoveryResult)
}

fun createDevice(devId: String, devAg: DeviceAgentMfpMib) {
    val mfp = DeviceAgentMfpMib(id = devId, cluster = devAg.cluster, dev = DeviceDev(password = secretDefault))
    db.document("device/$devId").set(mfp)
    val mfpInitialQuery =
        DeviceMfpMib_QueryStatusUpdate(
            id = "statusUpdate",
            cluster = devAg.cluster,
            devId = devAg.id,
            schedule = Schedule(limit = 10, interval = 10 * 1000),
        )
    db.document("device/$devId/query/${mfpInitialQuery.id}").set(mfpInitialQuery)
}

