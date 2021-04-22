import com.google.cloud.firestore.FirestoreOptions
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.collect
import mibtool.snmp4jWrapper.sendFlow
import org.snmp4j.CommunityTarget
import org.snmp4j.PDU
import org.snmp4j.Snmp
import org.snmp4j.smi.OctetString
import org.snmp4j.smi.UdpAddress
import org.snmp4j.transport.DefaultUdpTransportMapping
import java.net.InetAddress


// GOOGLE_APPLICATION_CREDENTIALS=//pathto/road-to-iot-8efd3bfb2ccd.json
val db = FirestoreOptions.getDefaultInstance().getService()
val snmp = Snmp(DefaultUdpTransportMapping().apply { listen() })
val secretDefault = "Sharp_#1"

@ExperimentalCoroutinesApi
suspend fun main2() {
    runAgent("stressAgent1", "1234eeee")
}

@ExperimentalCoroutinesApi
suspend fun main() {

    snmp.sendFlow(PDU(), CommunityTarget(
            UdpAddress(InetAddress.getByName("10.36.102.245"), 161),
            OctetString("public"),
    )).collect {

    }
}
