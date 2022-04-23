package snmpDevice

import firebaseInterOp.*
import firebaseInterOp.Firestore.*
import firebaseInterOp.await
import gdvm.agent.mib.GdvmDeviceInfo
import gdvm.agent.mib.GdvmTime
import io.ktor.utils.io.core.*
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.datetime.Clock
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import snmp.*

@Serializable
data class GdvmSnmpDevice(
    val id: String, // same as document.id
    val time: GdvmTime = Clock.System.now().toEpochMilliseconds(),
    val type: List<String> = mutableListOf("dev", "dev.mfp", "dev.snmp"),

    val dev: GdvmDeviceInfo,
    val snmp: SnmpTarget,
    val tags: List<String> = mutableListOf("type:dev", "type:dev.mfp", "type:dev.snmp"),
)


// device/{SnmpDevice}/query/{SnmpDevice_Query}
@Serializable
data class SnmpDevice_Query(
    val schedule: Schedule = Schedule(1),
    val pdu: PDU,
    val time: GdvmTime = Clock.System.now().toEpochMilliseconds(),
    val result: String = "", //document reference to response. "" is no response.
)

// device/{SnmpDevice}/query/{SnmpDevice_Query}/result/{SnmpDevice_Query_Result}
@Serializable
data class SnmpDevice_Log_VB(
    val id: String, // same as document.id
    //val type: List<String> = mutableListOf("log", "log.dev", "log.dev.snmp", "log.dev.snmp.varbind"),
    val vb: Log_VB,
    val time: GdvmTime = Clock.System.now().toEpochMilliseconds(),
    //val tags: List<String> = mutableListOf("log", "log.dev", "log.dev.snmp", "log.dev.snmp.varbind"),
)

@Serializable
data class Log_VB(
    val oid: String,
    val sOid: String,
    val stx: Byte,
    val num: Long? = null,
    val str: String? = null,
)

@Serializable
data class Schedule(
    val limit: Int = 1, //　回数は有限に。失敗すると破産するし
    val interval: Long = 0,
)

@InternalCoroutinesApi
@ExperimentalCoroutinesApi
suspend fun runSnmpDevice(firebase: App, deviceId: String, secret: String) {
    println("Start SNMP Device ID:$deviceId  (Ctrl-C to Terminate)")

    val db = firebase.firestore()
    val devRef = db.collection("device").doc(deviceId)
    val devQueryRef = devRef.collection("query")
    callbackFlow {
        devQueryRef.where("result", "==", "").onSnapshot { //TODO orderBy
            offer(it)
        }
        awaitClose { }
    }.collectLatest { queriesSS ->
        queriesSS.docs.forEach { querySS ->
            GlobalScope.launch { querySnmp(devRef, querySS.ref, querySS) }
        }
        //TODO update query executed
    }
    println("Terminated SNMP Device ID:$deviceId    (Ctrl-C to Terminate)")

}

suspend fun querySnmp(devRef: DocumentReference, queryRef: DocumentReference, querySs: QueryDocumentSnapshot) {
    println("Start SNMP Device Query Path: ${queryRef.path}") //TODO
    val dev = devRef.get().await().dataAs<GdvmSnmpDevice>()!!
    //println(dev) //TODO
    val devQuery = querySs.dataAs<SnmpDevice_Query>()!!
    //println(devQuery) //TODO
    val snmpSession = SnmpSession.create(dev.snmp)

    callbackFlow {
        snmpSession.send(devQuery.pdu) { pdu ->
            when (pdu) {
                null -> close()
                else -> offer(pdu)
            }
        }
        awaitClose {}
    }.collectLatest { pdu ->

        println(pdu)//TODO
        val now = Clock.System.now().toEpochMilliseconds()
        pdu.vbl.forEach { vb ->
            val log = SnmpDevice_Log_VB(id = vb.oid, vb = vb.toLog(), time = now)
            devRef.collection("status").document(vb.oid).set(log)
            devRef.collection("logs").document().set(log)
        }

    }
}


@ExperimentalUnsignedTypes
fun ByteArray.toLong() = reversed().fold(0L) { a, e -> (a shl 8) or e.toUByte().toLong() }

@ExperimentalUnsignedTypes
fun VarBind.toLog(): Log_VB {
    fun Iterable<Byte>.toSortableBase64() = (this + listOf(0, 0)).toList().windowed(3, 3, false) {
        it.fold(0) { a, e -> (a shl 8) or e.toUByte().toInt() }
    }.flatMap {
        (3 downTo 0).map { i -> (it shr (i * 6)) and 0x3f }.map {
            "+0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz"[it]
        }
    }.joinToString("")

    fun Int.toByteArray() = ByteArray(4) { (this shr (it * 8)).toByte() }
    fun String.toSortableOid() = split(".").flatMap { it.toInt().toByteArray().toList()}.toSortableBase64()
        
    println("soid=${oid.toSortableOid()}") //TODO

    val v = value
    return when (this.value.syntax) {
        Variable.INTEGER32,
        Variable.IPADDRESS,
        Variable.COUNTER32 -> Log_VB(
            oid = oid, sOid = oid.toSortableOid(), num = v.buff.toLong(), stx = this.value.syntax
        )

        Variable.OID,
        Variable.GAUGE32,
        Variable.TIMETICKS,
        Variable.COUNTER64 -> Log_VB(
            oid = oid,
            sOid = oid.toSortableOid(),
            num = v.buff.toLong(),
            stx = this.value.syntax
        )

        Variable.BITSTRING,
        Variable.OCTETSTRING,
        Variable.OPAQUE -> Log_VB(
            oid = oid,
            sOid = oid.toSortableOid(),
            str = v.buff.decodeToString(),
            stx = this.value.syntax
        )

        Variable.NOSUCHOBJECT,
        Variable.NOSUCHINSTANCE,
        Variable.ENDOFMIBVIEW -> Log_VB(oid = oid, sOid = oid.toSortableOid(), str = "", stx = this.value.syntax)

        else -> throw Exception("Unknown Type of Variable: $v")
    }
}
