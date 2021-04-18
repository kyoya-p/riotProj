import com.google.cloud.firestore.DocumentReference
import com.google.cloud.firestore.DocumentSnapshot
import com.google.cloud.firestore.FirestoreOptions
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.*
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

@Serializable
data class X(
    val a: Int
)

val db = FirestoreOptions.getDefaultInstance().getService()

fun DocumentReference.snapshots() = callbackFlow<DocumentSnapshot> {
    val listener = addSnapshotListener { value, error -> if (value != null) offer(value) }
    awaitClose { listener.remove() }
}

fun <T> DocumentReference.snapshotsAs(op: (T) -> Unit) = snapshots().flatMapConcat {
    channelFlow {
        if (it.data != null) {

            offer(1)
        }
    }
}

suspend fun main() {
    db.collection("device").document("stress1").snapshots().collect {
        val v = JsonObject(it.data as Map<String, JsonElement>)
        println("v=$v") //TODO
    }
}