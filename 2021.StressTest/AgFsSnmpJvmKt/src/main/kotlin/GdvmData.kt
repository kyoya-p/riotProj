package gdvm.device

import com.google.gson.JsonIOException
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import mibtool.snmp4jWrapper.GETNEXT
import org.snmp4j.smi.VariableBinding
import java.util.*


// device/{device}
@Serializable
data class Device(
    val id: String,
    val time: Long,
    val cluster: String,
    val dev: DeviceDev,
    val type: List<String> = listOf("dev"),
    val tags: List<String> = listOf(),
)

@Serializable
data class DeviceDev(
    val password: String = "Sharp_#1",
)


@Serializable
data class SnmpTarget(
    val addr: String,
    val port: Int = 161,
    val credential: Credential = Credential(),
    val retries: Int = 5,
    val interval: Long = 5000,

    val isBroadcast: Boolean = false, // for discovery by broadcast
    val addrRangeEnd: String? = null, // for IP ranged discovery
)

@Serializable
data class Credential(
    val ver: String = "1",
    val v1commStr: String = "public",
    // v3...
)


@Serializable
data class PDU(
    val type: Int = GETNEXT,
    val vbl: List<VB> = listOf(VB(".1.3")),
    val errSt: Int = 0,
    val errIdx: Int = 0,
)

val ASN_UNIVERSAL get() = 0x00
val ASN_APPLICATION get() = 0x40
val NULL get() = ASN_UNIVERSAL or 0x05
val OCTETSTRING get() = ASN_UNIVERSAL or 0x04
val IPADDRESS get() = ASN_APPLICATION or 0x00

@Serializable
data class VB(
    val oid: String,
    val stx: Int = NULL,
    val value: String = "",
)



@Serializable
data class Schedule(
    val limit: Int = 1, //　0は実行しない
    val interval: Long = 0,
)

@Serializable
data class VarBind(
    val oid: String,
    val value: String,
    val type: Int,
)

