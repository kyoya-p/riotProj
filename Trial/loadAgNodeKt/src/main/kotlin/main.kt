import dev.gitlive.firebase.Firebase
import dev.gitlive.firebase.FirebaseOptions
import dev.gitlive.firebase.auth.FirebaseUser
import dev.gitlive.firebase.auth.auth
import dev.gitlive.firebase.firestore.firestore
import dev.gitlive.firebase.initialize
import gdvm.agent.mib.GdvmGenericDevice
import io.ktor.client.*
import io.ktor.client.request.*
import io.ktor.http.*
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.*
import kotlin.js.Date

external val process: dynamic
val args: Array<String> get() = process.argv

@ExperimentalCoroutinesApi
suspend fun main() {
    try {
        println("Start client")

        //process.env["NODE_TLS_REJECT_UNAUTHORIZED"] = "0" // TLS証明書チェックをバイパス
        //process.env["GLOBAL_AGENT_HTTP_PROXY"] = "http://10.144.98.32:3080/"
        //require("global-agent/bootstrap")

        val opts = FirebaseOptions(
            applicationId = "1:307495712434:web:acc483c0c300549ff33bab",
            apiKey = "AIzaSyDrO7W7Sb6RCpHTsY3GaP-zODRP_HtY4nI",
            databaseUrl = "https://road-to-iot.firebaseio.com",
            projectId = "road-to-iot",
        )
        Firebase.initialize(context = null, options = opts)
        println("Initialized Database")

        val devId = "Display"
        val secret = "1234eeee"
        siginInWithCustomTokenFlow(devId, secret).collectLatest {
            when (it) {
                is FirebaseUser -> println("loggedin: ${it.uid}")
                else -> println("not loggedin.")
            }
        }
        println("Terminated clint")
    } catch (e: Exception) {
        e.printStackTrace()
    }

}

suspend fun siginInWithCustomTokenFlow(deviceId: String, secret: String): Flow<FirebaseUser?> = run {
    val customTokenSvr = "https://us-central1-road-to-iot.cloudfunctions.net/requestToken"
    val urlQuery = listOf("id" to deviceId, "pw" to secret).formUrlEncode()
    val urlCustomToken = "$customTokenSvr/customToken?$urlQuery"
    println("Request Custom Token: $urlCustomToken")
    val customToken = HttpClient().get<String>(urlCustomToken)
    val auth = Firebase.auth
    auth.signInWithCustomToken(customToken)
    return auth.authStateChanged
}

