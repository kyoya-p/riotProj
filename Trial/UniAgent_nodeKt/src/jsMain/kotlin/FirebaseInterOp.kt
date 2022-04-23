package firebaseInterOp

import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.promise
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.*
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine
import kotlin.js.Promise


external fun require(module: String): dynamic //javascriptのrequire()を呼ぶ

suspend fun <T> Promise<T>.await(): T = suspendCoroutine { cont ->
    then({ cont.resume(it) }, { cont.resumeWithException(it) })
}

class Firebase {
    companion object {
        fun initializeApp(apiKey: String, authDomain: String, projectId: String, name: String? = null): App {
            val ga = require("global-agent")
            ga.bootstrap()

            // See: https://medium.com/faun/firebase-accessing-firestore-and-firebase-through-a-proxy-server-c6c6029cddb1
            val HttpsProxyAgent = require("https-proxy-agent")
            val agent = HttpsProxyAgent("http://admin:admin@172.29.241.32:807")

            val firebase = require("firebase/app")
            require("firebase/auth")
            require("firebase/firestore")
            data class Config(
                val apiKey: String, val authDomain: String, val projectId: String, val httpAgent: dynamic,
            )
            name ?: return App(firebase.initializeApp(Config(apiKey, authDomain, projectId, agent)))
            return App(firebase.initializeApp(Config(apiKey, authDomain, projectId, agent), name))
        }
    }
}

class App(val raw: dynamic) {
    fun auth() = Auth(raw.auth())
    fun auth(app: App) = Auth(raw.auth(app.raw))
    fun firestore() = Firestore(raw.firestore())
    fun firestore(app: App) = Firestore(raw.firestore(app.raw))

    val name: String get() = raw.name
    fun delete(): Promise<Any> = raw.delete()

    class Auth(val raw: dynamic) {
        fun signInWithEmailAndPassword(email: String, password: String): Unit =
            raw.signInWithEmailAndPassword(email, password)

        fun signInWithCustomToken(token: String): Unit =
            raw.signInWithCustomToken(token)

        fun onAuthStateChanged(op: (User?) -> Unit): Unit =
            raw.onAuthStateChanged { user -> op(if (user != null) User(user) else null) }

        val currentUser = User(raw.currentUser)
    }

    // https://firebase.google.com/docs/reference/js/firebase.User
    data class User(private val raw: dynamic) {
        val uid: String get() = raw.uid
    }
}

class Firestore(val raw: dynamic) {
    fun collection(path: String) = CollectionReference(raw.collection(path))

    class ListenerRegistration(val raw: dynamic) {
        fun remove(): Unit = raw()
    }

    open class Query(val raw: dynamic) {
        fun where(fieldPath: String, opStr: String, value: Any?): Query {
            return Query(raw.where(fieldPath, opStr, value))
        }

        fun select(vararg fields: String) = Query(raw.select(fields))

        //fun addSnapshotListener(listener: EventListener<QuerySnapshot>): ListenerRegistration =
        //    ListenerRegistration(raw.onSnapshot { doc -> listener.onEvent(QuerySnapshot(doc)) })
        fun addSnapshotListener(listener: (QuerySnapshot?) -> Unit): ListenerRegistration =
            ListenerRegistration(raw.onSnapshot { doc -> listener(QuerySnapshot(doc)) })

        fun onSnapshot(listener: (QuerySnapshot) -> Unit): ListenerRegistration =
            ListenerRegistration(raw.onSnapshot { doc ->
                listener(QuerySnapshot(doc))
            })
    }

    class CollectionReference(raw: dynamic) : Query(raw) {
        fun document(path: String) = DocumentReference(raw.doc(path))
        fun doc(path: String) = document(path)
        fun document() = DocumentReference(raw.doc())
        fun doc() = document()
    }

    class DocumentReference(val raw: dynamic) {
        fun collection(id: String) = CollectionReference(raw.collection(id))

        fun get(): Promise<DocumentSnapshot> =
            GlobalScope.promise { raw.get().then { d -> return@then DocumentSnapshot(d) } }

        fun get(field: String): Promise<DocumentSnapshot> =
            GlobalScope.promise { raw.get(field).then { d -> return@then DocumentSnapshot(d) } }

        /*inline fun set(doc: String): Promise<Unit> =
            //GlobalScope.promise { raw.set(js("Object").assign(js("{}"),doc)).then { return@then Unit } }
            GlobalScope.promise { raw.set(js("JSON").parse(doc)).then { return@then Unit } }
*/
        inline suspend fun <reified T> set(doc: T): Promise<Unit> {
            //GlobalScope.promise { raw.set(js("Object").assign(js("{}"),doc)).then { return@then Unit } }
            val str = Json.encodeToString(doc)
            val jsObj = js("JSON").parse(str)
            return GlobalScope.promise { raw.set(jsObj).then { return@then Unit } }
        }

        fun addSnapshotListener(listener: (DocumentSnapshot?) -> Unit): ListenerRegistration =
            ListenerRegistration(raw.onSnapshot { doc -> listener(DocumentSnapshot(doc)) })

        val path: String get() = raw.path
    }

    fun interface EventListener<T> {
        fun onEvent(snapshot: T?): Unit //TODO
    }

    class DocumentSnapshot(val raw: dynamic) {
        val id: String get() = raw.id
        val ref: DocumentReference get() = DocumentReference(raw.ref)

        val data: JsonObject?
            get() {
                val data = raw.data() ?: return null
                return Json { ignoreUnknownKeys = true }.decodeFromString(JSON.stringify(data))
            }

        inline fun <reified T> dataAs(): T? {
            val data = raw.data() ?: return null
            return Json { ignoreUnknownKeys = true }.decodeFromString<T>(JSON.stringify(data))
        }
    }

    class QuerySnapshot(val raw: dynamic) {
        val docs: List<QueryDocumentSnapshot>
            get() = (0 until raw.size as Int).map { QueryDocumentSnapshot(raw.docs[it]) }

        val size: Int get() = raw.size
    }

    class QueryDocumentSnapshot(val raw: dynamic) {
        val ref: DocumentReference get() = DocumentReference(raw.ref)
        fun data(): JsonObject? {
            val data = raw.data() ?: return null
            return Json { ignoreUnknownKeys = true }.decodeFromString(JSON.stringify(data))
        }

        inline fun <reified T> dataAs(): T? {
            val data = raw.data() ?: return null
            return Json { ignoreUnknownKeys = true }.decodeFromString<T>(JSON.stringify(data))
        }
    }
}

inline fun <reified T> JsonElement.toObject(): T = Json {}.decodeFromString(JSON.stringify(this))
inline fun <reified T> Firestore.QueryDocumentSnapshot.toObject(): T? {
    return Json {}.decodeFromString<T>(JSON.stringify(raw.data() ?: return null))
}

inline fun <reified T> Firestore.DocumentSnapshot.toObject(): T? {
    return Json {}.decodeFromString<T>(JSON.stringify(raw.data() ?: return null))
}

@Suppress("UNCHECKED_CAST")
fun Any?.toJsonElement(): JsonElement {
    return when {
        this == null -> JsonNull
        this is JsonPrimitive -> this
        this is JsonObject -> this
        this is JsonArray -> this
        this is Map<*, *> -> (this as Map<String, Any>).toJsonObject()
        this is List<*> -> (this as List<Any>).toJsonArray()
        this is Boolean -> JsonPrimitive(this)
        this is Number -> JsonPrimitive(this)
        this is String -> JsonPrimitive(this)
        else -> throw IllegalStateException("in toJsonElement(): Type missmatch: ${this}")
    }
}

fun Any.toJsonObject(): JsonObject {
    val t = this
    if (t is JsonObject) return t
    if (t is Map<*, *>) {
        t as Map<String, *>
        return buildJsonObject {
            t.forEach { (k, v) -> put(k, v.toJsonElement()) }
        }
    }
    throw IllegalStateException("Any.toJsonObject() this=$this")
}

fun Any.toJsonArray(): JsonArray {
    val t = this
    if (t is JsonArray) return t
    if (t is List<*>) {
        return buildJsonArray { t.forEach { add(it.toJsonElement()) } }
    }
    throw IllegalStateException("Any.toJsonArray() this=$this")
}

