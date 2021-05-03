import com.google.cloud.firestore.*
import gdvm.device.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import mibtool.snmp4jWrapper.*
import org.snmp4j.smi.OID
import java.util.*
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine
import kotlin.random.Random
import kotlin.Exception as Exception1


@Serializable
data class DeviceMfpSnmp(
    val time: Long = Date().time,
    val id: String,
    val cluster: String,
    val createdBy: String,

    val dev: DeviceDev,
    val type: List<String> = listOf("dev", "dev.mfp", "dev.mfp.snmp", "dev.detected"),
    val tags: List<String> = listOf(),
    val attr: Map<String, JsonElement> = mapOf(
        "dev" to JsonObject(mapOf("mfp" to JsonObject(mapOf()))),
    ),
)

@Suppress("ClassName")
@Serializable
data class DeviceMfpMib_QueryStatusUpdate(
    val time: Long = Date().time,
    val id: String,
    val type: List<String> = listOf("query.mfp.snmp.statusUpdate"),
    val devId: String,
    val cluster: String,
    val schedule: Schedule = Schedule(1),
)

@Suppress("ClassName")
@Serializable
data class DeviceMfpMib_QueryStatusUpdate_Result(
    val time: Long = Date().time,
    val devId: String,
    val cluster: String,

    val vbs: List<VB>
)

@Serializable
data class Counter(
    val count: Int = 0,
    val devId: String,
    val cluster: String,
    val time: Long = Date().time,
    val attr: Map<String, JsonElement> = mapOf(
        "log" to JsonObject(
            mapOf(
                "mfp" to JsonObject(mapOf()),
                "snmp" to JsonObject(mapOf()),
            ),
        )
    ),
)


@ExperimentalCoroutinesApi
suspend fun runMfpSnmp(devMfpId: String, secret: String, address: String) = runCatching {
    println("${Date()} ----- Start runMfpSnmp($devMfpId,$address)")

    val dev = db.document("device/$devMfpId").dataAs<DeviceMfpSnmp>() ?: throw Exception1("No Device device/$devMfpId")
    db.collection("device/$devMfpId/query")
        .whereEqualTo("cluster", "AgentStressTest").limit(3)
        .snapshotsAs<DeviceMfpMib_QueryStatusUpdate>().collect { queries ->
            queries.forEach { query -> runMfpSnmpQuery(query.id, dev, query, address) }
        }
}.onFailure { it.printStackTrace() }.getOrThrow()

@ExperimentalCoroutinesApi
suspend fun runMfpSnmp_StressTester(devMfpId: String, secret: String, address: String) = runCatching {

    @ExperimentalCoroutinesApi
    suspend fun runMfpSnmpQuery_StressTest(
        name: String,
        dev: DeviceMfpSnmp,
        query: DeviceMfpMib_QueryStatusUpdate,
        address: String
    ) {
        val counterInfo = Counter(count = 0, devId = dev.id, cluster = dev.cluster)
        repeat(query.schedule.limit) { qn ->
            delay(query.schedule.interval)
            setWithShardCounter(db.collection("device/${dev.id}/counter"), dev.id, 1, counterInfo) {
                val log = DeviceMfpMib_QueryStatusUpdate_Result(
                    devId = dev.id,
                    cluster = dev.cluster,
                    vbs = listOf(VB(oid = "1.3.6.1"), VB(oid = "1.3.6.2"), VB(oid = "1.3.6.3"))
                )
                db.collection("device/${dev.id}/logs").document().set(log)
            }
            println("${Date()} [$qn] Report[${dev.id}]") //TODO
        }
    }

    println("${Date()} ----- Start runMfpSnmp_StressTester($devMfpId,$address)")
    val dev =
        db.document("device/$devMfpId").dataAs<DeviceMfpSnmp>() ?: throw Exception1("No Device of device/$devMfpId")
    val queries = db.collection("device/$devMfpId/query")
        .whereEqualTo("cluster", "AgentStressTest").limit(3).get().get()
        ?: throw Exception("No Query of device/$devMfpId")
    queries.forEach { ss ->
        val type = (ss["type"] ?: listOf<String>()) as List<String>
        when {
            type.contains("query.mfp.snmp.statusUpdate") -> runMfpSnmpQuery_StressTest(
                ss.id, dev, ss.dataAs<DeviceMfpMib_QueryStatusUpdate>()!!, address
            )
            else -> {
            }
        }
    }

}.onFailure { it.printStackTrace() }.getOrThrow()

@ExperimentalCoroutinesApi
suspend fun runMfpSnmpQuery(name: String, dev: DeviceMfpSnmp, query: DeviceMfpMib_QueryStatusUpdate, address: String) =
//    coroutineScope {
    runCatching {
        println("${Date()} ----- Start runMfpSnmpQuery(${dev.id},${query.id})")
        val counterInfo = Counter(count = 0, devId = dev.id, cluster = dev.cluster)
        scheduleFlow(query.schedule).collect { qn ->
            val reqVBL = listOf(hrDeviceStatus, hrPrinterStatus, hrPrinterDetectedErrorState).map { VB(oid = it) }
            val target = SnmpTarget(address, 161).toSnmp4j()

            snmp.sendFlow(pdu = PDU(GETNEXT, reqVBL).toSnmp4j(), target = target).collect { res ->
                setWithShardCounter(db.collection("device/${dev.id}/counter"), dev.id, 1, counterInfo) {
                    val log = DeviceMfpMib_QueryStatusUpdate_Result(
                        devId = dev.id,
                        cluster = dev.cluster,
                        vbs = res.response?.variableBindings?.map { VB.from(it) } ?: listOf()
                    )
                    db.collection("device/${dev.id}/logs").document().set(log)
                }
                println("${Date()} [$qn] Report[${dev.id}]") //TODO
            }
        }
    }.onFailure { it.printStackTrace() }.getOrThrow()
//   }

val rand = Random(Date().time)

@ExperimentalCoroutinesApi
suspend fun setWithShardCounter(
    counter: CollectionReference,
    prefix: String,
    dispersion: Int,
    counterData: Counter,
    op: (transaction: Transaction) -> Unit
) {
    counter.firestore.runTransactionSuspendable { transaction ->
        val r = rand.nextInt(dispersion)
        val counterShard = counter.document("$prefix.$r")
        runCatching {
            val c = counterShard.dataAs<Counter>() ?: counterData.copy(count = 0)
            op(transaction)
            counterShard.set(counterData.copy(count = c.count + 1, time = Date().time))
        }.onFailure { println(it) }// TODO
    }
}

suspend inline fun <T> Firestore.runTransactionSuspendable(crossinline callback: suspend (Transaction) -> T) =
    suspendCoroutine<T> { continuation ->
        runTransaction { transaction ->
            runBlocking { continuation.resume(callback(transaction)) }
        }
    }
