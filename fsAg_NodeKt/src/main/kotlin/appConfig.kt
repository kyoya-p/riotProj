import dev.gitlive.firebase.Firebase
import dev.gitlive.firebase.FirebaseApp
import dev.gitlive.firebase.FirebaseOptions
import dev.gitlive.firebase.auth.FirebaseUser
import dev.gitlive.firebase.auth.auth
import dev.gitlive.firebase.initialize
import io.ktor.client.*
import io.ktor.client.request.*
import io.ktor.http.*
import kotlinx.coroutines.flow.Flow

val opts = FirebaseOptions(
    applicationId = "1:307495712434:web:acc483c0c300549ff33bab",
    apiKey = "AIzaSyDrO7W7Sb6RCpHTsY3GaP-zODRP_HtY4nI",
    databaseUrl = "https://road-to-iot.firebaseio.com",
    projectId = "road-to-iot",
)

fun initalizeFirebaseApp(name: String) = Firebase.initialize(context = null, options = opts, name = name)
fun initalizeFirebaseApp() = Firebase.initialize(context = null, options = opts)

suspend fun siginInWithCustomToken(app: FirebaseApp, deviceId: String, secret: String): Flow<FirebaseUser?> = run {
    // debug
    fun String.fromBase64() = chunked(4).map {
        it.map { "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".indexOf(it) }
            .foldIndexed(0) { i, a, e -> a or (e shl (18 - 6 * i)) }
    }.flatMap { (0..2).map { i -> (it shr (16 - 8 * i) and 255).toChar() } }.joinToString("")

    fun String.claim() = split(".").drop(1).first().fromBase64()

    val customTokenSvr = "https://us-central1-road-to-iot.cloudfunctions.net/requestToken"
    val urlQuery = listOf("id" to deviceId, "pw" to secret).formUrlEncode()
    val urlCustomToken = "$customTokenSvr/customToken?$urlQuery"
    println("Request Custom Token: $urlCustomToken")
    val customToken = HttpClient().get<String>(urlCustomToken)
    println("Custom Token Claim ${customToken.claim()}") //TODO debug

    val auth = Firebase.auth(app)
    auth.signInWithCustomToken(customToken)
    return auth.authStateChanged
}


