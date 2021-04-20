import com.google.cloud.firestore.FirestoreOptions
import kotlinx.coroutines.ExperimentalCoroutinesApi
import org.snmp4j.Snmp
import org.snmp4j.transport.DefaultUdpTransportMapping


// GOOGLE_APPLICATION_CREDENTIALS=//pathto/road-to-iot-8efd3bfb2ccd.json
val db = FirestoreOptions.getDefaultInstance().getService()
val snmp = Snmp(DefaultUdpTransportMapping().apply { listen() })
val secretDefault = "Sharp_#1"

@ExperimentalCoroutinesApi
suspend fun main() {
    runAgent("stressAgent1", "1234eeee")
}

