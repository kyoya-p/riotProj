package gdvm.device

import kotlinx.serialization.Serializable
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
data class DeviceMfpMib(
    val time: Long,
    val id: String,
    val cluster: String,

    val dev: DeviceDev,
    val type: List<String> = listOf("dev", "dev.mfp", "dev.mfp.snmp", "dev.detected"),
    val tags: List<String> = listOf(),
)

@Serializable
data class DeviceAgentMfpMib(
    val time: Long,
    val id: String,
    val cluster: String,
    val dev: DeviceDev,
)

// device/{}/query/{query}
@Serializable
data class DeviceAgentMfpMib_Query(
    val scanAddrSpecs: List<SnmpTarget>,
    val autoRegistration: Boolean = false,
    val schedule: Schedule = Schedule(1),
    val time: Long? = null,
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

val GET: Int get() = -96
val GETNEXT: Int get() = -95
val RESPONSE: Int get() = -94
val SET: Int get() = -93

val sysDescr get() = ".1.3.6.1.2.1.1.1"
val sysObjectID get() = ".1.3.6.1.2.1.1.2"
val sysName get() = ".1.3.6.1.2.1.1.5"
val sysLocation get() = ".1.3.6.1.2.1.1.6"

val hrDeviceStatus get() = ".1.3.6.1.4.1.11.2.3.9.4.2.3.3.2.1.5"
val hrDeviceDescr get() = ".1.3.6.1.2.1.25.3.2.1.3"
val hrPrinterStatus get() = ".1.3.6.1.2.1.25.3.5.1.1"
val hrPrinterDetectedErrorState get() = ".1.3.6.1.2.1.25.3.5.1.2"
val prtGeneralSerialNumber get() = ".1.3.6.1.2.1.43.5.1.1.17"


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
data class GdvmLog(
    val cluster: String,
    val targets: List<String> = listOf(),
)

@Serializable
data class LogReport(
    val time: Long,
    val deviceId: String,
    val type: List<String> = listOf("log", "log.dev", "log.dev.agent", "log.dev.agent.mfp", "log.dev.agent.mfp.snmp"),
    val log: GdvmLog,
    val result: Result = Result(),
)

@Serializable
data class Result(
    val detected: List<String> = listOf()
)
