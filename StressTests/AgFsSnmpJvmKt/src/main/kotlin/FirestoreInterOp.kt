import com.google.cloud.firestore.*
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.callbackFlow

import kotlinx.serialization.json.*
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

val db = FirestoreOptions.getDefaultInstance().getService()
inline fun <reified T> DocumentSnapshot.dataAs(): T? = data?.toJsonObject()?.toObject<T>()

// callbackをcoroutineに変換
@ExperimentalCoroutinesApi
suspend inline fun <reified T> DocumentReference.dataAs(): T? {
    val listener: ListenerRegistration
    val r = suspendCoroutine<T?> { continuation ->
        listener = addSnapshotListener { v, e ->
            when {
                v != null -> continuation.resume(v.dataAs<T>())
                e is Throwable -> continuation.resumeWithException(e)
                else -> continuation.resume(null) // resumeWithException(Exception("No Document"))
            }
        }
    }

    // resume()後に呼び出されるコールバックはないものか runCatching{}.onSuccess{}みたいな
    listener.remove()
    return r
}

inline fun <reified T> QuerySnapshot.dataAs(): List<T> = documents.mapNotNull { it?.dataAs<T>() }

@ExperimentalCoroutinesApi
suspend inline fun <reified T> Query.dataAs(): List<T>? {
    val listener: ListenerRegistration
    val r = suspendCoroutine<List<T>?> { continuation ->
        listener = addSnapshotListener { v, e ->
            when {
                v != null -> continuation.resume(v.dataAs())
                e is Throwable -> continuation.resumeWithException(e)
                else -> continuation.resume(null)
            }
        }
    }

    // resume()後に呼び出されるコールバックはないものか runCatching{}.onSuccess{}みたいな
    listener.remove()
    return r
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
        runCatching {
            if (error != null) {
                println("Error: ${error.message}")
            } else if (value != null) {
                offer(value.documents.map { it.data.toJsonObject().toObject() })
            }
        }.onFailure { close() }.onSuccess { }.getOrThrow()
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


