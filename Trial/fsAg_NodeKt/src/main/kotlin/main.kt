import dev.gitlive.firebase.Firebase
import dev.gitlive.firebase.auth.auth
import dev.gitlive.firebase.firestore.firestore
import gdvm.schema.GenericDevice
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

external val process: dynamic
val args: Array<String> get() = process.argv

@FlowPreview
@InternalCoroutinesApi
@ExperimentalCoroutinesApi
suspend fun main(): Unit = GlobalScope.launch {
    if (args.size != 4) {
        println("syntax: node UniAgent.js <agentId> <secret>")
        return@launch
    }
    val deviceId = args[2]
    val secret = args[3]
    runGenericDevice(deviceId, secret)
}.join()

// 汎用デバイス
// 認証後、与えられたidに対応するtype情報を取得し、対応するProxyDevice/Agentを起動する
@FlowPreview
@ExperimentalCoroutinesApi
@InternalCoroutinesApi
suspend fun runGenericDevice(deviceId: String, secret: String) {
//    val fbApp = myFirebaseApp(deviceId)
    val fbApp = initalizeFirebaseApp()

    siginInWithCustomToken(fbApp, deviceId, secret).collectLatest { // Signed-in
//        val auth = Firebase.auth(fbApp)
//        val db = Firebase.firestore(fbApp) //バグ?(複数アカウントでDB同時アクセスできない)

        val auth = Firebase.auth
        val db = Firebase.firestore
        println("Signed-in:  User:${auth.currentUser?.uid}")
        val dev = db.collection("device").document(deviceId).get().data<GenericDevice>()
        println("Device Type: ${dev.type}")

        when {
            dev.type.contains("dev.stress") -> runStressDevice(fbApp, dev)
            //type["dev"]["agent"]["snmp"] != null -> runSnmpAgent(firebase, deviceId, secret)
            //type["dev"]["agent"]["stressTest"] != null -> runStressTestAgent(firebase, deviceId, secret)
            //type["dev"]["agent"]["launcher"] != null -> runLauncherAgent(firebase, deviceId, secret)
        }
    }
}
