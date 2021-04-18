import com.google.cloud.firestore.FirestoreOptions
import gdvm.device.DeviceAgentMfpMib_Query
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.*


// GOOGLE_APPLICATION_CREDENTIALS=/path/to/road-to-iot-8efd3bfb2ccd.json
val db = FirestoreOptions.getDefaultInstance().getService()

@ExperimentalCoroutinesApi
suspend fun main() {
    db.collection("device").document("stressAgent1").collection("query")
        .whereEqualTo("cluster","AgentStressTest").limit(3)
        .snapshotsAs<DeviceAgentMfpMib_Query>().collect { query ->
            println("d=${query}") //TODO
        }
}