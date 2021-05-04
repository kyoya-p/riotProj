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
    val mfpInitialQueryTemplate: DeviceMfpMib_QueryStatusUpdate? = null,

    val dummyDeviceInstances: Int? = null
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
        val dev = db.document("device/$devAgentId").dataAs<DeviceAgentMfpMib>()!!
        db.collection("device/$devAgentId/query")
            .whereEqualTo("cluster", "AgentStressTest").limit(3)
            .snapshotsAs<DeviceAgentMfpMib_QueryDiscovery>().collectLatest { queries ->
                //queries.forEach { query -> launch { runAgentQuery(dev, query) } }
                queries.forEach { query -> runAgentQuery(dev, query) }
            }
    }.onFailure { println("${Date()} Canceled runAgent($devAgentId)  Exception:") }
}

var sched = 0

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
    scheduleFlow(query.schedule).collectLatest { i ->
        println("${Date()} ----- Start runAgentQuery(${devAg.id}/${query.id}:$i )")
        val discoveryResList = if (query.dummyDeviceInstances == null || query.dummyDeviceInstances == 0) {
            query.scanAddrSpecs.asFlow().discoveryDeviceMap(snmp, reqOids).map { res ->
                val (model, sn) = res.response.variableBindings.map { it.variable.toString() }
                val devId = "type=dev.mfp.snmp:model=$model:sn=$sn"
                DiscoveryResult(devId, res.peerAddress.inetAddress.hostAddress)
            }.toList().distinctBy { it.devId }
        } else {
            (0 until query.dummyDeviceInstances).map {
                DiscoveryResult(
                    devId = "type=dev.mfp.dmy:${devAg.id}:no=$it",
                    ip = "127.0.0.1"
                )
            }
        }

        sendReport(devAg, query.id, discoveryResList.map { it.devId })

        if (query.autoRegistration) discoveryResList.forEach { dev ->
            delay(100) //TODO
            launch {
                createDevice(dev.devId, devAg)
                createDeviceQuery(dev.devId, devAg, query)
                runCatching {
                    when (query.dummyDeviceInstances) {
                        null, 0 -> runMfpSnmp(dev.devId, secretDefault, dev.ip)
                        else -> runMfpSnmp_StressTester(dev.devId, secretDefault, dev.ip)
                    }
                }.onFailure { it.printStackTrace() }
            }
        }
    }
}

fun sendReport(devAg: DeviceAgentMfpMib, queryId: String, result: List<String>) {
    val discoveryResult =
        DeviceAgentMfpMib_ResultDiscovery(devId = devAg.id, cluster = devAg.cluster, detected = result)
    db.collection("device/${devAg.id}/logs").document().set(discoveryResult)
    db.document("device/${devAg.id}/state/$queryId").set(discoveryResult)
}

fun createDevice(devId: String, devAg: DeviceAgentMfpMib) {
    val mfp =
        DeviceMfpSnmp(
            id = devId,
            cluster = devAg.cluster,
            dev = DeviceDev(password = secretDefault),
            createdBy = devAg.id,
            type = listOf("dev", "dev.mfp", "dev.mfp.dmy")
        )
    db.document("device/$devId").set(mfp)
}

fun createDeviceQuery(devId: String, devAg: DeviceAgentMfpMib, query: DeviceAgentMfpMib_QueryDiscovery) {
    val qt = query.mfpInitialQueryTemplate ?: DeviceMfpMib_QueryStatusUpdate(
        id = "statusUpdate",
        type = listOf("query.mfp.snmp.statusUpdate"),
        cluster = devAg.cluster,
        devId = devId,
        schedule = Schedule(limit = 2, interval = 1 * 1000),
    )
    val mfpInitialQuery = qt.copy(devId = devId, cluster = devAg.cluster)
    db.document("device/$devId/query/${mfpInitialQuery.id}").set(mfpInitialQuery)
}

