package snmpDevice

import firebaseInterOp.*
import firebaseInterOp.Firestore.*
import firebaseInterOp.await
import gdvm.agent.mib.GdvmDeviceInfo
import gdvm.agent.mib.GdvmTime
import io.ktor.http.*
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.datetime.Clock
import kotlinx.serialization.Serializable
import netSnmp.*
import kotlin.js.Date
import kotlin.js.json

@Serializable
data class GdvmSnmpDevice(
    val id: String, // same as document.id
    val time: GdvmTime = Date().getUTCMilliseconds() as Long,
    val type: List<String> = listOf("dev", "dev.mfp", "dev.snmp"),

    val dev: GdvmDeviceInfo,
    val snmp: SnmpTarget,
    val tags: List<String> = listOf(),
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
data class SnmpDevice_Query_Result(
    val vbl: List<VB>,
    val time: Long = Clock.System.now().toEpochMilliseconds(),
    val tags: List<String> = listOf()
)

/// for Agent ------
@Serializable
data class SnmpAgentQuery_Discovery(
    val scanAddrSpecs: List<SnmpTarget>,
    val autoRegistration: Boolean,
    val schedule: Schedule = Schedule(1),
    val time: Long? = null,
)

// device/{SnmpAgent}/query/{SnmpAgentQuery_DeviceBridge}
@Serializable
data class SnmpAgentQuery_DeviceBridge(
    val targets: List<GdvmSnmpDevice>,
    val time: Long? = null,
)

@Serializable
data class Schedule(
    val limit: Int = 1, //　回数は有限に。失敗すると破産するし
    val interval: Long = 0,
)

@InternalCoroutinesApi
@ExperimentalCoroutinesApi
suspend fun runSnmpDevice(firebase: App, deviceId: String, secret: String) {
    println("Start SNMP Device ID:$deviceId    (Ctrl-C to Terminate)")

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
    println("Start SNMP Device Query Path:${queryRef.path}") //TODO
    val dev = devRef.get().await().dataAs<GdvmSnmpDevice>()!!
    println(dev) //TODO
    val devQuery = querySs.dataAs<SnmpDevice_Query>()!!
    println(devQuery) //TODO
    val snmpSession = Snmp.createSession(dev.snmp.addr, dev.snmp.credential.v1commStr)

    val callback = { error: dynamic, varbinds: List<VarBind> ->
        println("callback") //TODO
        when (error) {
            null -> {
                val vbl = json("vbl" to varbinds.map {
                    json(
                        "oid" to it.oid,
                        "type" to it.type,
                        "value" to it.value,
                    )
                }.toTypedArray())
                queryRef.collection("result").doc().set(vbl)
                varbinds.forEach { println(it) } //TODO
                //devRef.collection("logs").doc().set(SnmpDevice_Query_Result(varbinds.map {
                //    VB(oid=it.oid)
                //}))
            }
            else -> println("Error: $error")
        }
    }
    val oids = devQuery.pdu.vbl.map { it.oid }.toTypedArray()
    println("xxx") //TODO
    when (devQuery.pdu.type) {
        GET -> snmpSession.get(oids, callback)
        GETNEXT -> snmpSession.getNext(oids, callback)
    }
}


