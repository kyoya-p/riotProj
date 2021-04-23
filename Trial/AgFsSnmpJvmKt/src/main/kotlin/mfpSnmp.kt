import gdvm.device.*
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.*
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import mibtool.snmp4jWrapper.*
import java.util.*


@Serializable
data class DeviceMfpSnmp(
        val time: Long = Date().time,
        val id: String,
        val cluster: String,

        val dev: DeviceDev,
        val type: List<String> = listOf("dev", "dev.mfp", "dev.mfp.snmp", "dev.detected"),
        val tags: List<String> = listOf(),
        val attr: Map<String, JsonElement> = mapOf(
                "dev" to JsonObject(mapOf("mfp" to JsonObject(mapOf()))),
        ),
)

@Serializable
data class DeviceMfpMib_QueryStatusUpdate(
        val time: Long = Date().time,
        val id: String,
        val devId: String,
        val cluster: String,

        val schedule: Schedule = Schedule(1),
)

var mfpQueryCount = 0; //TODO

@ExperimentalCoroutinesApi
suspend fun runMfpSnmp(devMfpId: String, secret: String, address: String) {
    runCatching {
        println("${Date()}      ----- Start runMfpSnmp[$address]($devMfpId)")
        val dev = db.document("device/$devMfpId").get().get().data?.toJsonObject()?.toObject<DeviceMfpSnmp>()!!
        db.collection("device/$devMfpId/query")
                .whereEqualTo("cluster", "AgentStressTest").limit(3)
                .snapshotsAs<DeviceMfpMib_QueryStatusUpdate>().collectLatest { queries ->
                    queries.forEach { query ->
                        runMfpSnmpQuery(dev, query, address)
                    }
                }
    }.onFailure { ex -> println("${Date()} Canceled runMfpSnmp($devMfpId)  Exception:") }

}

suspend fun runMfpSnmpQuery(dev: DeviceMfpSnmp, query: DeviceMfpMib_QueryStatusUpdate, address: String) {
    val c = mfpQueryCount++
    println(" --- S$c")
    runCatching {
        //println("${Date()} Start Device Query: device/${dev.id}/query/${query.id}")
        scheduleFlow(query.schedule).collectLatest {
            val reqVBL = listOf(hrDeviceStatus, hrPrinterStatus, hrPrinterDetectedErrorState).map { VB(oid = it) }
            val target = SnmpTarget(address, 161).toSnmp4j()
            snmp.sendFlow(pdu = PDU(GETNEXT, reqVBL).toSnmp4j(), target = target).collect {
                println("${Date()} Report: ${it.peerAddress?.inetAddress?.hostAddress} ${it.response?.variableBindings}") //TODO
            }
        }
    }//.onFailure { ex -> println("${Date()} Terminate runMfpSnmpQuery(): ${query.id}  Exception: $ex") }
    println("     E$c")
    mfpQueryCount++
}
