package snmp

import kotlinx.serialization.Serializable

expect class SnmpSession {
    companion object {
        fun create(target: SnmpTarget): SnmpSession
    }

    fun close()
    fun send(pdu: PDU, callback: (PDU?) -> Any?)
}

@Serializable
data class Variable(val syntax: Byte, val buff: ByteArray) {
    companion object {
        const val ASN_UNIVERSAL = 0x00.toByte()
        const val ASN_APPLICATION = 0x40.toByte()

        const val INTEGER: Byte = 0x00 or 0x02
        const val INTEGER32: Byte = 0x00 or 0x02
        const val BITSTRING: Byte = 0x00 or 0x03
        const val OCTETSTRING: Byte = 0x00 or 0x04
        const val NULL: Byte = 0x00 or 0x05
        const val OID: Byte = 0x00 or 0x06
        const val SEQUENCE: Byte = 0x00 or 0x10

        const val IPADDRESS: Byte = 0x40 or 0x00
        const val COUNTER: Byte = 0x40 or 0x01
        const val COUNTER32: Byte = 0x40 or 0x01
        const val GAUGE: Byte = 0x40 or 0x02
        const val GAUGE32: Byte = 0x40 or 0x02
        const val TIMETICKS: Byte = 0x40 or 0x03
        const val OPAQUE: Byte = 0x40 or 0x04
        const val COUNTER64: Byte = 0x40 or 0x06

        const val NOSUCHOBJECT: Byte = 0x80.toByte()
        const val NOSUCHINSTANCE: Byte = 0x81.toByte()
        const val ENDOFMIBVIEW: Byte = 0x82.toByte()
    }
}

@Serializable
data class VarBind(val oid: String, val value: Variable = Variable(Variable.NULL, ByteArray(0)))

@Serializable
data class PDU(
    val type: Int = PDU.RESPONSE,
    val vbl: List<VarBind>,
    val errSt: Int = 0,
    val errIdx: Int = 0,
) {
    companion object {
        val GET: Int get() = -96
        val GETNEXT: Int get() = -95
        val RESPONSE: Int get() = -94
        val SET: Int get() = -93
    }
}

@Serializable
data class Credential(
    val ver: String = "2c",
    val v1commStr: String = "public",
    // TODO v3...
)

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

val sysDescr get() = "1.3.6.1.2.1.1.1"
val sysObjectID get() = "1.3.6.1.2.1.1.2"
val sysName get() = "1.3.6.1.2.1.1.5"
val sysLocation get() = "1.3.6.1.2.1.1.6"

val hrDeviceStatus get() = "1.3.6.1.4.1.11.2.3.9.4.23.3.2.1.5"
val hrDeviceDescr get() = "1.3.6.1.2.1.25.3.2.1.3"
val hrPrinterStatus get() = "1.3.6.1.2.1.25.3.5.1.1"
val hrPrinterDetectedErrorState get() = "1.3.6.1.2.1.25.3.5.1.2"
val prtGeneralSerialNumber get() = "1.3.6.1.2.1.43.5.1.1.17"

