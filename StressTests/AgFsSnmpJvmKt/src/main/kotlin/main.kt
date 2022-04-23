import com.google.cloud.firestore.FirestoreOptions
import kotlinx.coroutines.ExperimentalCoroutinesApi


// GOOGLE_APPLICATION_CREDENTIALS=//pathto/road-to-iot-8efd3bfb2ccd.json
val secretDefault = "Sharp_#1"

@ExperimentalCoroutinesApi
suspend fun main(args: Array<String>) {
    if (args.size != 2) {
        println(
            """
            syntax: java -jar AgFsSnmpJvmKt.jar <agentId> <secret>
        """.trimIndent()
        )
        return
    }
    runAgent(args[0], args[1])
}

