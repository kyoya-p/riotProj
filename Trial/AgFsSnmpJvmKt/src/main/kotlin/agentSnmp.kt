import gdvm.device.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
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

        val debugDummyInstances: Int = 1
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
suspend fun runAgent(devAgentId: String, secret: String) {
    runCatching {
        println("${Date()} ----- Start runAgent($devAgentId)")
        val dev = db.document("device/$devAgentId").get().get().data?.toJsonObject()?.toObject<DeviceAgentMfpMib>()!!
        db.collection("device/$devAgentId/query")
                .whereEqualTo("cluster", "AgentStressTest").limit(3)
                .snapshotsAs<DeviceAgentMfpMib_QueryDiscovery>().collectLatest { queries ->
                    //queries.forEach { query -> launch { runAgentQuery(dev, query) } }
                    queries.forEach { query -> runAgentQuery(dev, query) }
                }
    }.onFailure { ex -> println("${Date()} Canceled runAgent($devAgentId)  Exception:") }
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
    runCatching {
        //println("${Date()} Start runAgentQuery(${query.id})")
        val reqOids = listOf(hrDeviceDescr, prtGeneralSerialNumber)
        scheduleFlow(query.schedule).collectLatest {
            val res = query.scanAddrSpecs.asFlow().discoveryDeviceMap(snmp, reqOids).map { res ->
                val model = res.response.variableBindings[0].variable.toString()
                val sn = res.response.variableBindings[1].variable.toString()
                val devId = "type=dev.mfp.snmp:model=$model:sn=$sn"
                if (query.autoRegistration) {
                    createDevice(devId, devAg)
                    repeat(query.debugDummyInstances) {
                        GlobalScope.launch {
                            println("S$it")
                            runMfpSnmp(devId, secretDefault, res.peerAddress.inetAddress.hostAddress)
                            println("E$it")
                        }
                    }
                }
                devId
            }.toList()
            sendReport(devAg, query.id, res)
        }
    }
    //.onFailure { ex -> println("${Date()} Canceled runAgentQuery(${query.id})  Exception: $ex") }
    //.onSuccess { println("${Date()} Terminate runAgentQuery(${query.id})") }
}

fun sendReport(devAg: DeviceAgentMfpMib, queryId: String, result: List<String>) {
    val discoveryResult =
            DeviceAgentMfpMib_ResultDiscovery(devId = devAg.id, cluster = devAg.cluster, detected = result)
    db.collection("device/${devAg.id}/logs").document().set(discoveryResult)
    db.document("device/${devAg.id}/state/$queryId").set(discoveryResult)
}

fun createDevice(devId: String, devAg: DeviceAgentMfpMib) {
    val mfp = DeviceMfpSnmp(id = devId, cluster = devAg.cluster, dev = DeviceDev(password = secretDefault))
    db.document("device/$devId").set(mfp)
    val mfpInitialQuery =
            DeviceMfpMib_QueryStatusUpdate(
                    id = "statusUpdate",
                    cluster = devAg.cluster,
                    devId = devAg.id,
                    schedule = Schedule(limit = 1, interval = 1 * 1000),
            )
    db.document("device/$devId/query/${mfpInitialQuery.id}").set(mfpInitialQuery)
}

