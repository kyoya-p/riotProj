import gdvm.device.*
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlinx.serialization.Serializable
import mibtool.snmp4jWrapper.*
import org.snmp4j.smi.UdpAddress
import java.util.*


@Serializable
data class DeviceMfpSnmp(
    val time: Long,
    val id: String,
    val cluster: String,

    val dev: DeviceDev,
    val type: List<String> = listOf("dev", "dev.mfp", "dev.mfp.snmp", "dev.detected"),
    val tags: List<String> = listOf(),
)

@Serializable
data class DeviceMfpMib_QueryStatusUpdate(
    val time: Long = Date().time,
    val id: String,
    val devId: String,
    val cluster: String,

    val schedule: Schedule = Schedule(1),
)

@ExperimentalCoroutinesApi
suspend fun runMfpSnmp(devMfpId: String, secret: String, address: String) = coroutineScope {
    try {
        val dev = db.document("device/$devMfpId").get().get().data?.toJsonObject()?.toObject<DeviceMfpSnmp>()!!
        println("Start deviceId: $devMfpId")
        db.collection("device/$devMfpId/query")
            .whereEqualTo("cluster", "AgentStressTest").limit(3)
            .snapshotsAs<DeviceMfpMib_QueryStatusUpdate>().collectLatest { queries ->
                queries.forEachIndexed { i, query ->
                    launch {
                        scheduleFlow(query.schedule).collect {
                            launch { runMfpSnmpQuery(dev, query, address) }
                        }
                    }
                }
            }
    } finally {
        println("Terminated deviceId: $devMfpId")//TODO
    }
}

suspend fun runMfpSnmpQuery(dev: DeviceMfpSnmp, query: DeviceMfpMib_QueryStatusUpdate, address: String) {
    println("Updated query: $query")//TODO
    val reqVBL = listOf(hrDeviceStatus, hrPrinterStatus, hrPrinterDetectedErrorState).map { VB(oid = it) }
    val target = SnmpTarget(address, 161).toSnmp4j()
    snmp.sendFlow(pdu = PDU(GETNEXT, reqVBL).toSnmp4j(), target = target).collect {
        println("${it.response?.variableBindings}") //TODO
    }
}
