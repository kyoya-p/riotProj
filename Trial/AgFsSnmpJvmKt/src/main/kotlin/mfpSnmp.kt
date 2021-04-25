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
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine


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

var mfpDevCount = Sem("mfp") //TODO

suspend fun <R> gate(sem: Sem, op: suspend () -> R): R =
    runCatching {
        sem.enter("{")
        op()
    }.onFailure { sem.leave("}") }.onSuccess { sem.leave("x}") }.getOrThrow()

/*
@ExperimentalCoroutinesApi
suspend fun runMfpSnmp(devMfpId: String, secret: String, address: String) = gate(mfpDevCount) {
    //println("${Date()}      ----- Start runMfpSnmp[$address]($devMfpId)")
    db.document("device/$devMfpId").addSnapshotListener { v, e ->
        if (e == null && v != null) {
            val dev = v.data?.toJsonObject()?.toObject<DeviceMfpSnmp>()!!
            db.collection("device/$devMfpId/query")
                .whereEqualTo("cluster", "AgentStressTest").limit(3)
                .snapshots().collectLatest { v ->
                }
        }
    }
}
*/

// callbackをcoroutineに変換
@ExperimentalCoroutinesApi
inline suspend fun <reified T : Any> DocumentReference.dataAs(): T {
    val listener: ListenerRegistration
    val r = suspendCoroutine<T> { continuation ->
        listener = addSnapshotListener { v, e ->
            when {
                v != null -> continuation.resume(v.data?.toJsonObject()?.toObject<T>()!!)
                e is Throwable -> continuation.resumeWithException(e)
                else -> continuation.resumeWithException(Exception("Unknown"))
            }
        }
    }
    // resume()後に呼び出されるコールバックはないものか runCatching{}.onSuccess{}みたいな
    listener.remove()
    return r
}


@ExperimentalCoroutinesApi
suspend fun runMfpSnmp(devMfpId: String, secret: String, address: String) = coroutineScope {
    val dev = db.document("device/$devMfpId").dataAs<DeviceMfpSnmp>()
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
                }
            }
        }.onFailure { it.printStackTrace() }.getOrThrow()
    }
