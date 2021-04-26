import com.google.cloud.firestore.*
import com.google.cloud.firestore.EventListener
import gdvm.device.*
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.*
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import mibtool.snmp4jWrapper.*
import java.util.*
import kotlin.collections.RandomAccess
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine
import kotlin.random.Random


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

class Sem(val name: String, var count: Int = 0) {
    fun enter(msg: String = "") = println("  E($name:$msg:${count++})")
    fun leave(msg: String = "") = println("  L($name:$msg:${--count})")
}


@ExperimentalCoroutinesApi
suspend fun runMfpSnmp(devMfpId: String, secret: String, address: String) = coroutineScope {
    val dev = db.document("device/$devMfpId").dataAs<DeviceMfpSnmp>() ?: throw Exception("No Device device/$devMfpId")
    db.collection("device/$devMfpId/query")
            .whereEqualTo("cluster", "AgentStressTest").limit(3)
            .snapshotsAs<DeviceMfpMib_QueryStatusUpdate>().collectLatest { queries ->
                queries.forEach { query ->
                    launch {
                        runCatching {
                            runMfpSnmpQuery("${query.id}", dev, query, address)
                        }.onFailure { it.printStackTrace() }
                    }
                }
            }
}

@ExperimentalCoroutinesApi
suspend fun runMfpSnmpQuery(name: String, dev: DeviceMfpSnmp, query: DeviceMfpMib_QueryStatusUpdate, address: String) =
        coroutineScope {
            runCatching {
                scheduleFlow(query.schedule).collectLatest {
                    val reqVBL = listOf(hrDeviceStatus, hrPrinterStatus, hrPrinterDetectedErrorState).map { VB(oid = it) }
                    val target = SnmpTarget(address, 161).toSnmp4j()
                    snmp.sendFlow(pdu = PDU(GETNEXT, reqVBL).toSnmp4j(), target = target).collect {
                        println("${Date().time} Report[$name]: ${it.peerAddress?.inetAddress?.hostAddress} ${it.response?.variableBindings}") //TODO
                        setWithDispersionCounter(db.collection("device/${dev.id}/logs"), 10)
                    }
                }
            }.onFailure { it.printStackTrace() }.getOrThrow()
        }

val _rand = Random(Date().time)

@ExperimentalCoroutinesApi
suspend fun addWithDispersionCounter(counter: CollectionReference, dispersion: Int, op: () -> Unit) {
    @Serializable
    data class Counter(val count: Int = 0)
    counter.firestore.runTransaction {
        val r = _rand.nextInt(dispersion)
        val counterShard = counter.document("$r")
        val c = counterShard.dataAs<Counter>() ?: Counter(0)
        op()
        counter.add(Counter(c.count + 1))
    }azu
}

@ExperimentalCoroutinesApi
suspend fun incrementDispersionCounter(counter: DocumentReference, dispersion: Int) {

}