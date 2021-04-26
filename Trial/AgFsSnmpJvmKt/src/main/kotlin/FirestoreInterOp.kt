import com.google.cloud.firestore.*
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.callbackFlow

import kotlinx.serialization.json.*
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine


// callbackをcoroutineに変換
@ExperimentalCoroutinesApi
suspend inline fun <reified T> DocumentReference.dataAs(): T? {
    val listener: ListenerRegistration
    //println("C1")//TODO
    val r = suspendCoroutine<T?> { continuation ->
        //println("C2")//TODO
        listener = addSnapshotListener { v, e ->
            //println("C3")//TODO
            when {
                v != null -> continuation.resume(v.data?.toJsonObject()?.toObject<T>())
                e is Throwable -> continuation.resumeWithException(e)
                else -> continuation.resume(null) // resumeWithException(Exception("No Document"))
            }
            //println("C4")//TODO
        }
    }
    //println("C5")//TODO

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
