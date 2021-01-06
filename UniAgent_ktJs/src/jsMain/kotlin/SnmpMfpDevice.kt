package snmpMfpDevice

import firebaseInterOp.*
import firebaseInterOp.Firestore.*
import firebaseInterOp.await
import gdvm.agent.mib.GdvmDeviceInfo
import kotlinx.coroutines.*
import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.MapSerializer
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import netSnmp.*
import kotlin.js.json

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
    println("Start SNMP Device ID:$deviceId    (Ctrl-C to Terminate)")

    val db = firebase.firestore()
    val devRef = db.collection("device").doc(deviceId)
    val devQueryRef = devRef.collection("query")
    devQueryRef.where("responded", "==", false).onSnapshot { querySS ->
        querySS.docs.forEach { querySs ->
            GlobalScope.launch { querySnmp(devRef, querySs.ref, querySs) }
        }
    }
}

private suspend inline fun <reified R> DocumentReference.body(): R =
    Json { ignoreUnknownKeys = true }.decodeFromString<R>(Json {}.encodeToString(this@body.get().await().data))

private inline fun <reified R> DocumentSnapshot.body(): R =
    Json { ignoreUnknownKeys = true }.decodeFromString<R>(Json {}.encodeToString(this@body.data))

suspend fun querySnmp(devRef: DocumentReference, queryRef: DocumentReference, querySs: QueryDocumentSnapshot) {
    println("Start SNMP Device Query Path:${queryRef.path}") //TODO
    val dev = devRef.get().await().dataAs<SnmpDevice>()!!

    val devQuery = querySs.dataAs<SnmpDevice_Query>()!!
    val snmpSession = Snmp.createSession(dev.target.addr, dev.target.credential.v1commStr)

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


