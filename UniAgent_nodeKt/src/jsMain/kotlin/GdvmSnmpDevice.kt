package snmpDevice

import firebaseInterOp.*
import firebaseInterOp.Firestore.*
import firebaseInterOp.await
import gdvm.agent.mib.GdvmDeviceInfo
import gdvm.agent.mib.GdvmTime
import kotlinx.coroutines.*
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
    val reqTime: Long? = null,
    val responded: Boolean,
)

// device/{SnmpDevice}/query/{SnmpDevice_Query}/result/{SnmpDevice_Query_Result}
@Serializable
data class SnmpDevice_Query_Result(
    val schedule: Schedule = Schedule(1),
    val pdu: PDU,
    val time: Long? = null,
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
    devQueryRef.where("responded", "==", false).onSnapshot { queriesSS ->
        queriesSS.docs.forEach { querySS ->
            GlobalScope.launch { querySnmp(devRef, querySS.ref, querySS) }
        }
    }
    println("Terminated SNMP Device ID:$deviceId    (Ctrl-C to Terminate)")

}

suspend fun querySnmp(devRef: DocumentReference, queryRef: DocumentReference, querySs: QueryDocumentSnapshot) {
    println("Start SNMP Device Query Path:${queryRef.path}") //TODO
    val dev = devRef.get().await().dataAs<GdvmSnmpDevice>()!!

    val devQuery = querySs.dataAs<SnmpDevice_Query>()!!
    val snmpSession = Snmp.createSession(dev.snmp.addr, dev.snmp.credential.v1commStr)

    val callback = { error: dynamic, varbinds: List<VarBind> ->
        println("callback") //TODO
        when (error) {
            null -> {
                val vbl = json("vbl" to varbinds.map {
                    json(
                        "oid" to it.oid,
                        "type" to it.type,
                        "value" to it.value.toString(),
                    )
                }.toTypedArray())
                queryRef.collection("result").doc().set(vbl)
                varbinds.forEach { println(it) } //TODO
            }
            else -> println("Error: $error")
        }
    }
    when (devQuery.pdu.type) {
        GET -> snmpSession.get(devQuery.pdu.vbl.map { it.oid }.toTypedArray(), callback)
        GETNEXT -> snmpSession.getNext(devQuery.pdu.vbl.map { it.oid }.toTypedArray(), callback)
    }
}


