import com.google.cloud.firestore.*
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.callbackFlow

import kotlinx.serialization.json.*

@ExperimentalCoroutinesApi
fun DocumentReference.snapshot() = callbackFlow {
    val listener = addSnapshotListener { value, _ -> if (value != null) offer(value) }
    awaitClose { listener.remove() }
}

@ExperimentalCoroutinesApi
fun Query.snapshots() = callbackFlow {
    val listener = addSnapshotListener { value, _ -> if (value != null) offer(value) }
    awaitClose { listener.remove() }
}

@ExperimentalCoroutinesApi
inline fun <reified T : Any> DocumentReference.snapshotAs() = callbackFlow<T> {
    val listener = addSnapshotListener { value, error ->
        if (error == null && value != null && value.data != null) {
            offer(value.data!!.toJsonObject().toObject())
        }
    }
    awaitClose { listener.remove() }
}

@ExperimentalCoroutinesApi
inline fun <reified T : Any> Query.snapshotsAs() = callbackFlow<List<T>> {
    val listener = addSnapshotListener { value, error ->
        if (error != null) {
            println("Error: ${error.message}")
        } else if (value != null) {
            offer(value.documents.map { it.data.toJsonObject().toObject() })
        }
    }
    awaitClose { listener.remove() }
}

fun Map<String, Any>.toJsonObject(): JsonObject = buildJsonObject {
    forEach { (k, v) ->
        when (v) {
            is Number -> put(k, v)
            is String -> put(k, v)
            is Boolean -> put(k, v)
            is Map<*, *> -> put(k, (v as Map<String, Any>).toJsonObject())
            is List<*> -> put(k, (v as List<Any>).toJsonArray())
        }
    }
}

fun List<Any>.toJsonArray(): JsonArray = buildJsonArray {
    forEach { v ->
        when (v) {
            is Number -> add(v)
            is String -> add(v)
            is Boolean -> add(v)
            is Map<*, *> -> add((v as Map<String, Any>).toJsonObject())
            is List<*> -> add((v as List<Any>).toJsonArray())
        }
    }
}

inline fun <reified T> JsonObject.toObject(): T = Json { ignoreUnknownKeys = true }.decodeFromJsonElement(this)
