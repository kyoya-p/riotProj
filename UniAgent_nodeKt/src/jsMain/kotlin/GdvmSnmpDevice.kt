package snmpDevice

import firebaseInterOp.*
import firebaseInterOp.Firestore.*
import firebaseInterOp.await
import gdvm.agent.mib.GdvmDeviceInfo
import gdvm.agent.mib.GdvmTime
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.datetime.Clock
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.encodeToJsonElement
import snmp.*
import kotlin.js.Date

@Serializable
data class GdvmSnmpDevice(
    val id: String, // same as document.id
    val time: GdvmTime = Date().getUTCMilliseconds() as Long,
    val type: List<String> = listOf("dev", "dev.mfp", "dev.snmp"),

    val dev: GdvmDeviceInfo,
    val snmp: SnmpTarget,
    val tags: List<String> = listOf("type:dev", "type:dev.mfp", "type:dev.snmp"),
)


// device/{SnmpDevice}/query/{SnmpDevice_Query}
@Serializable
data class SnmpDevice_Query(
    val schedule: Schedule = Schedule(1),
    val pdu: PDU,
    val time: Long = Clock.System.now().toEpochMilliseconds(),
    val result: String = "", //document reference to response. "" is no response.
)

// device/{SnmpDevice}/query/{SnmpDevice_Query}/result/{SnmpDevice_Query_Result}
@Serializable
data class SnmpDevice_Log_VB(
    val id: String, // same as document.id
    val type: List<String> = listOf("log", "log.dev", "log.dev.snmp", "log.dev.snmp.varbind"),
    val vb: Log_VB,
    val time: GdvmTime = Date().getUTCMilliseconds() as Long,
    val tags: List<String> = listOf("log", "log.dev", "log.dev.snmp", "log.dev.snmp.varbind"),
)

@Serializable
data class Log_VB(
    val oid: String,
    //val num: Long? = null,
    //val str: String? = null,
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
        val time = Clock.System.now().toEpochMilliseconds()
        pdu.vbl.forEach {
            println("Log=${it.toLog()}")//TODO
            devRef.collection("status").document("oid").set(Json.encodeToJsonElement(mapOf("a" to 111)))
            //devRef.collection("status").document("oid").set(it.toLog())
        }

    }
}


fun VarBind.toLog(): Log_VB {
    fun Variable.toInt() = this.buff.fold(0) { a, e -> (a shl 8) + e.toInt() }
    fun Variable.toLong() = this.buff.fold(0L) { a, e -> (a shl 8) + e.toInt() }

    val v = this.value
    return when (this.value.syntax) {
        Variable.INTEGER32,
        Variable.IPADDRESS,
        Variable.COUNTER32 -> Log_VB(oid = this.oid)//num = v.toInt().toLong())

        Variable.OID,
        Variable.GAUGE32,
        Variable.TIMETICKS,
        Variable.COUNTER64 -> Log_VB(oid = this.oid)//num = v.toLong())

        Variable.BITSTRING,
        Variable.OCTETSTRING,
        Variable.OPAQUE -> Log_VB(oid = this.oid)//str = v.buff.toString())

        Variable.NOSUCHOBJECT,
        Variable.NOSUCHINSTANCE,
        Variable.ENDOFMIBVIEW -> Log_VB(oid = this.oid)// str = "")

        else -> throw Exception("Unknown Type of Variable: $v")
    }
}
