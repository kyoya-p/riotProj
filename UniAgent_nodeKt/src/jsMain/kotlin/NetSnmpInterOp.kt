package netSnmp

import firebaseInterOp.require
import kotlinx.serialization.Serializable

/*
 https://github.com/markabrahams/node-net-snmp
 */

@Serializable
data class SnmpTarget(
    val addr: String,
    val port: Int = 161,
    val credential: Credential = Credential(),
    val retries: Int = 5,
    val interval: Long = 5000,

    val isBroadcast: Boolean? = false, // for discovery by broadcast
    val addrRangeEnd: String? = null, // for IP ranged discovery
)

@Serializable
data class Credential(
    val ver: String = "2c",
    val v1commStr: String = "public",
    // v3...
)

val GET: Int get() = -96
val GETNEXT: Int get() = -95
val RESPONSE: Int get() = -94
val SET: Int get() = -93

val sysDescr get() = "1.3.6.1.2.1.1.1"
val sysObjectID get() = "1.3.6.1.2.1.1.2"
val sysName get() = "1.3.6.1.2.1.1.5"
val sysLocation get() = "1.3.6.1.2.1.1.6"

val hrDeviceStatus get() = "1.3.6.1.4.1.11.2.3.9.4.2.3.3.2.1.5"
val hrDeviceDescr get() = "1.3.6.1.2.1.25.3.2.1.3"
val hrPrinterStatus get() = "1.3.6.1.2.1.25.3.5.1.1"
val hrPrinterDetectedErrorState get() = "1.3.6.1.2.1.25.3.5.1.2"
val prtGeneralSerialNumber get() = "1.3.6.1.2.1.43.5.1.1.17"


@Serializable
data class PDU(
    val type: Int = GETNEXT,
    val vbl: List<VB> = listOf(VB("1.3")),
    val errSt: Int = 0,
    val errIdx: Int = 0,
)

val ASN_UNIVERSAL get() = 0x00
val ASN_APPLICATION get() = 0x40
val NULL get() = ASN_UNIVERSAL or 0x05
val COUNTER get() = ASN_UNIVERSAL or 0x01
val COUNTER32 get() = ASN_UNIVERSAL or 0x02
val COUNTER64 get() = ASN_UNIVERSAL or 0x03
val DISPLAYSTRING get() = ASN_UNIVERSAL or 0x04

val GAUGE get() = ASN_UNIVERSAL or 0x05
val INTEGET get() = ASN_UNIVERSAL or 0x06
val INTEGET32 get() = ASN_UNIVERSAL or 0x07
val OCTETSTRING get() = ASN_UNIVERSAL or 0x08

val IPADDRESS get() = ASN_APPLICATION or 0x00

@Serializable
data class VB(
    val oid: String,
    val stx: Int = NULL,
    val value: String? = null,
) {
    companion object
}


fun variableToString(stx: Int, v: Any?): String? {
    println("stx=$stx")
    println("v=$v")
    return when (stx) {
        2 -> (v as Int).toString()
        4 -> v as String
        5 -> null
//        6 ->
//        64 -> IpAddress(v.uncaped().toList().toByteArray())
//        65 -> Counter32(v.toLong())
        //       66 -> Gauge32(v.toLong())
        //       67 -> TimeTicks(v.toLong())
        //       68 -> Opaque(v.toByteArray())
        //       70 -> Counter64(v.toLong())
        //       128 -> Null(128)
        //       129 -> Null(129)
        //       130 -> Null(130)
        else -> throw IllegalArgumentException("Unsupported variable syntax: ${stx}")
    }
}

class Snmp {
    companion object {
        fun createSession(host: String, community: String): Session {
            val snmp = require("net-snmp")
            return Session(snmp.createSession(host = host, community = community))
        }
    }
}

data class VarBind(val oid: String, val type: Int, val value: Any)

class Session(private val session: dynamic) {
    fun convVB(vb: dynamic): VarBind {
        println("vb=${vb}")
        println("vb.oid=${vb.oid}")
        println("vb.type=${vb.type as Int}")
        val res = VarBind(oid = vb.oid, type = vb.type, value = vb.value)
        println("vbres=${res}")
        return res
    }

    fun convVBL(vbl: dynamic) = (0 until vbl.length).map { convVB(vbl[it]) }

    fun getNext(oids: Array<String>, callback: (error: dynamic, varbinds: List<VarBind>) -> Any?) =
        session.getNext(oids, { error, varbinds ->
            when {
                error != null -> callback(error, listOf())
                else -> callback(null, convVBL(varbinds))
            }
        })

    fun get(oids: Array<String>, callback: (error: dynamic, varbinds: List<VarBind>) -> Any?) =
        session.get(oids, { error, varbinds ->
            when {
                error != null -> callback(error, listOf())
                else -> callback(null, convVBL(varbinds))
            }
        })
}

