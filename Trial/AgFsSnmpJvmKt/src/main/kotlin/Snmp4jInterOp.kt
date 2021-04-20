package mibtool.snmp4jWrapper

import gdvm.device.*
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import org.snmp4j.CommunityTarget
import org.snmp4j.Snmp
import org.snmp4j.Target
import org.snmp4j.event.ResponseEvent
import org.snmp4j.event.ResponseListener
import org.snmp4j.mp.SnmpConstants.*
import org.snmp4j.smi.*
import java.math.BigInteger
import java.net.InetAddress
import kotlin.random.Random

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

fun SnmpTarget.Companion.from(t: CommunityTarget<UdpAddress>) = SnmpTarget(
    addr = t.address.inetAddress.hostAddress,
    port = t.address.port,
    credential = Credential(
        ver = when (t.version) {
            version1 -> "1"
            version2c -> "2c"
            version3 -> "3"
            else -> ""
        },
        v1commStr = t.community.toString(),
    ),
    retries = t.retries,
    interval = t.timeout,
)

fun SnmpTarget.toSnmp4j() = CommunityTarget<UdpAddress>(
    UdpAddress(InetAddress.getByName(this.addr), 161),
    OctetString(this.credential.v1commStr),
)

fun PDU.Companion.from(pdu: org.snmp4j.PDU) = PDU(
    errSt = pdu.errorStatus,
    errIdx = pdu.errorIndex,
    type = pdu.type,
    vbl = pdu.variableBindings.map { it.toVB() }
)

fun PDU.toSnmp4j() = org.snmp4j.PDU().also {
    it.type = this.type
    //it.requestID
    it.variableBindings = this.vbl.map { it.toSnmp4j() }
}

fun String.toInetAddr() = InetAddress.getByName(this)!!
fun InetAddress.toBigInt() = BigInteger(address)
fun BigInteger.toInetAddr() =
    (ByteArray(16) + toByteArray()).takeLast(if (toByteArray().size <= 4) 4 else 16).toByteArray().let {
        InetAddress.getByAddress(it)!!
    }

fun scanIpRange(start: InetAddress, end: InetAddress) =
    generateSequence(start.toBigInt()) { it + BigInteger.ONE }.takeWhile { it <= end.toBigInt() }
        .map { it.toInetAddr() }

fun scanIpRange(start: String, end: String) = scanIpRange(InetAddress.getByName(start), InetAddress.getByName(end))

fun VariableBinding.toVB() = VB(
    oid = oid.toOidString(),
    stx = syntax,
    value = toValueString(),
)

fun OID.toOidString() = value.joinToString(".")
fun String.uncaped() = generateSequence(0 to 0.toByte()) { (i, c) ->
    when {
        i >= length -> null
        this[i] == ':' -> (i + 3) to substring(i + 1, i + 3).toInt(16).toByte()
        else -> (i + 1) to this[i].toByte()
    }
}.drop(1).map { it.second }


fun VB.toSnmp4j() = VariableBinding().also {
    it.oid = OID(this.oid)
    val v = value
    it.variable = when (stx) {
        2 -> Integer32(v.toInt())
        4 -> OctetString(v.uncaped().toList().toByteArray())
        5 -> Null()
        6 -> OID(v)
        64 -> IpAddress(v.uncaped().toList().toByteArray())
        65 -> Counter32(v.toLong())
        66 -> Gauge32(v.toLong())
        67 -> TimeTicks(v.toLong())
        68 -> Opaque(v.toByteArray())
        70 -> Counter64(v.toLong())
        128 -> Null(128)
        129 -> Null(129)
        130 -> Null(130)
        else -> throw IllegalArgumentException("Unsupported variable syntax: ${stx}")
    }
}

var _reqId = Random.nextInt()
suspend fun getGlobalRequestID(): Integer32 {
    val mtx = Mutex()
    mtx.lock()
    val r = _reqId++
    mtx.unlock()
    return Integer32(r)
}


@ExperimentalCoroutinesApi
suspend fun Snmp.sendFlow(pdu: org.snmp4j.PDU, target: Target<UdpAddress>) = callbackFlow<ResponseEvent<UdpAddress>> {
    pdu.requestID = getGlobalRequestID()
    println("Target: ${target.address}")
    send(pdu, target, target, object : ResponseListener {
        override fun <A : Address?> onResponse(event: ResponseEvent<A>) {
            val resPdu = event.response
            if (resPdu == null) {
                close()
            } else {
                offer(event as ResponseEvent<UdpAddress>) // テンプレート型のコールバックはどう扱えば?
            }
        }
    })
    awaitClose()
}

@ExperimentalCoroutinesApi
fun Snmp.scanFlow(pdu: org.snmp4j.PDU, startTarget: Target<UdpAddress>, endAddr: InetAddress) = channelFlow {
    scanIpRange(startTarget.address.inetAddress, endAddr).map { addr ->
        val launch = launch {
            sendFlow(pdu.apply { requestID = getGlobalRequestID() }, SnmpTarget(addr.hostAddress).toSnmp4j()).collect {
                offer(it)
            }
        }
        launch
    }.toList().forEach { it.join() }
    close()
    awaitClose()
}


@ExperimentalCoroutinesApi
suspend fun Snmp.broadcastFlow(pdu: org.snmp4j.PDU, target: Target<UdpAddress>) =
    callbackFlow<ResponseEvent<UdpAddress>> {
        val retries = target.retries
        target.retries = 0
        val detected = mutableSetOf<UdpAddress>()
        repeat(retries + 1) {
            sendFlow(pdu, target).collect {
                if (!detected.contains(it.peerAddress)) {
                    detected.add(it.peerAddress)
                    offer(it)
                }
            }
        }
        close()
        awaitClose()
    }


// 指定の条件でSNMP検索し、検索結果を流す
// depends: SNMP4J
@ExperimentalCoroutinesApi
suspend fun Flow<SnmpTarget>.discoveryDeviceMap(snmp: Snmp, oids: List<String>) = flatMapConcat { target ->
    println("Target: ${target}");//TODO
    callbackFlow {
        val sampleOids = oids.map { VB(it) }
        val pdu = PDU(GETNEXT, sampleOids)

        if (target.isBroadcast) {
            snmp.broadcastFlow(pdu.toSnmp4j(), target.toSnmp4j()).collect {
                offer(it)
            }
        } else {
            snmp.scanFlow(
                pdu.toSnmp4j(),
                target.toSnmp4j(),
                InetAddress.getByName(target.addrRangeEnd ?: target.addr)
            ).collect {
                offer(it)
            }
        }
    }

}
