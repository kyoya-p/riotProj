import com.google.cloud.firestore.FirestoreOptions
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.toList
import mibtool.snmp4jWrapper.request
import mibtool.snmp4jWrapper.sendFlow
import mibtool.snmp4jWrapper.walkFlow
import org.snmp4j.CommunityTarget
import org.snmp4j.PDU
import org.snmp4j.Snmp
import org.snmp4j.smi.OID
import org.snmp4j.smi.OctetString
import org.snmp4j.smi.UdpAddress
import org.snmp4j.smi.VariableBinding
import org.snmp4j.transport.DefaultUdpTransportMapping
import java.net.InetAddress
import java.util.*


// GOOGLE_APPLICATION_CREDENTIALS=//pathto/road-to-iot-8efd3bfb2ccd.json
val db = FirestoreOptions.getDefaultInstance().getService()
val snmp = Snmp(DefaultUdpTransportMapping().apply { listen() })
val secretDefault = "Sharp_#1"

@ExperimentalCoroutinesApi
suspend fun main() {
    runAgent("stressAgent1", "1234eeee")
}

@ExperimentalCoroutinesApi
suspend fun mainX() {
    val t0 = Date().time
    println("L0 ${Date().time - t0}")
    val r = snmp.walkFlow(
        PDU(PDU.GETNEXT, listOf(VariableBinding(OID("1.3")))), CommunityTarget(
            //UdpAddress(InetAddress.getByName("10.36.102.245"), 161),
            UdpAddress(InetAddress.getByName("192.168.3.8"), 161),
            OctetString("public"),
        )
    )

    println("L1 ${Date().time - t0}")
    val s = r.toList().size
    println(s)
    println("L2 ${Date().time - t0}")
}
