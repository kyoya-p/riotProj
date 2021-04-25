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

var sched = 0
var dummy = 0

@ExperimentalCoroutinesApi
suspend fun scheduleFlow(schedule: Schedule) = channelFlow {
    repeat(schedule.limit) { i ->
        sched = i  //TODO
        offer(i)
        delay(schedule.interval) //TODO 不正確 要対応
    }
}

@ExperimentalCoroutinesApi
suspend fun runAgentQuery(devAg: DeviceAgentMfpMib, query: DeviceAgentMfpMib_QueryDiscovery) = coroutineScope {

    @Serializable
    data class DiscoveryResult(val devId: String, val ip: String)

    val reqOids = listOf(hrDeviceDescr, prtGeneralSerialNumber)
    scheduleFlow(query.schedule).collectLatest {
        println("Sched:$it")
        val discoveryResList = query.scanAddrSpecs.asFlow().discoveryDeviceMap(snmp, reqOids).map { res ->
            val (model, sn) = res.response.variableBindings.map { it.variable.toString() }
            val devId = "type=dev.mfp.snmp:model=$model:sn=$sn"
            DiscoveryResult(devId, res.peerAddress.inetAddress.hostAddress)
        }.toList().distinctBy { it.devId }

        val discoveryResListDummy = when {
            query.debugDummyInstances == 0 -> discoveryResList
            else -> discoveryResList.flatMap { res ->
                (0 until query.debugDummyInstances).map { DiscoveryResult("${res.devId}:no=$it", res.ip) }
            }
        }
        sendReport(devAg, query.id, discoveryResListDummy.map { it.devId })

        /* if (query.autoRegistration) {
             createDevice(devId, devAg)
             repeat(query.debugDummyInstances) {
                 launch {
                     println("r1:$it")
                     runCatching {
                         runMfpSnmp(devId, secretDefault, res.peerAddress.inetAddress.hostAddress)
                     }.onFailure { it.printStackTrace() }
                     println("r2:$it")
                 }
             }
         }

         */
    }
}


fun sendReport(devAg: DeviceAgentMfpMib, queryId: String, result: List<String>) {
    val discoveryResult =
        DeviceAgentMfpMib_ResultDiscovery(devId = devAg.id, cluster = devAg.cluster, detected = result)
    db.collection("device/${devAg.id}/logs").document().set(discoveryResult)
    db.document("device/${devAg.id}/state/$queryId").set(discoveryResult)
    println(result) //TODO
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

