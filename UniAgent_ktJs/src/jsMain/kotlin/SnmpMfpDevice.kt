package snmpMfpDevice

import firebaseInterOp.App
import firebaseInterOp.Firestore.*
import firebaseInterOp.await
import gdvm.agent.mib.GdvmDeviceInfo
import kotlinx.coroutines.*
import kotlinx.serialization.Serializable
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import netSnmp.*

// device/{SnmpAgent}
@Serializable
data class SnmpDevide(
    val dev: GdvmDeviceInfo,
    val type: JsonObject, // {"dev":{"mfp":{"snmp":{}}}}
    val target: SnmpTarget,
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
    val targets: List<SnmpDevice>,
    val time: Long? = null,
)

@Serializable
data class SnmpDevice(
    val target: SnmpTarget,
    val deviceId: String? = null, // if defined, connecet platform with this ID.
    val password: String = "#1_Sharp",
)

@Serializable
data class Schedule(
    val limit: Int = 1, //　回数は有限に。失敗すると破産するし
    val interval: Long = 0,
)

@InternalCoroutinesApi
@ExperimentalCoroutinesApi
suspend fun runSnmpMfpDevice(firebase: App, deviceId: String, secret: String) {
    println("Start SNMP MFP Device ID:$deviceId    (Ctrl-C to Terminate)")

    val db = firebase.firestore()
    val devRef = db.collection("device").doc(deviceId)
    val devQueryRef = devRef.collection("query")
    devQueryRef.where("responded", "==", false).addSnapshotListener { querySS ->
        querySS?.data?.forEach { querySs ->
            val decoder = Json { ignoreUnknownKeys = true }
            //val query = decoder.decodeFromString<SnmpDevice_Query>(Json {}.encodeToString(ss.data))
            GlobalScope.launch {
                querySnmp(devRef, querySs.reference, querySs)
            }
        }
    }
}

private suspend inline fun <reified R> DocumentReference.body(): R =
    Json { ignoreUnknownKeys = true }.decodeFromString<R>(Json {}.encodeToString(this@body.get().await().data))

private suspend inline fun <reified R> DocumentSnapshot.body(): R =
    Json { ignoreUnknownKeys = true }.decodeFromString<R>(Json {}.encodeToString(this@body.data))

suspend fun querySnmp(devRef: DocumentReference, queryRef: DocumentReference, querySs: DocumentSnapshot) {
    val dev: SnmpDevice = devRef.body()
    val devQuery: SnmpDevice_Query = querySs.body()
    val snmpSession = Snmp.createSession(dev.target.addr, dev.target.credential.v1commStr)

    val callback = { error: dynamic, varbinds: List<VarBind> ->
        println("callback")
        when {
            error == null -> {
                varbinds.forEach {
                    println("${it} ${it.value}")
                }
                queryRef.collection("result").doc().set(varbinds)
            }
            else -> println("Error: $error")
        }
    }
    when (devQuery.pdu.type) {
        GET -> snmpSession.get(devQuery.pdu.vbl.map { it.oid }.toTypedArray(), callback)
        GETNEXT -> snmpSession.getNext(devQuery.pdu.vbl.map { it.oid }.toTypedArray(), callback)
    }
}


