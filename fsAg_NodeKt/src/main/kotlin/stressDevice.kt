import dev.gitlive.firebase.Firebase
import dev.gitlive.firebase.FirebaseApp
import dev.gitlive.firebase.firestore.DocumentSnapshot
import dev.gitlive.firebase.firestore.firestore
import dev.gitlive.firebase.firestore.where
import gdvm.schema.GenericDevice
import gdvm.schema.Schedule
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.*
import kotlinx.datetime.Clock
import kotlinx.serialization.Serializable
import kotlin.random.Random

@Serializable
data class DevStressQuery(
    val id: String,
    val cluster: String,
    val devId: String,
    val time: Int = 0, // time
    val schedule: Schedule = Schedule(),
    val result: Int? = null, // time
)

@Serializable
data class DevLog(
    val devId: String,
    val cluster: String,
    val time: Int = 0,
)

@Serializable
data class Count(
    val devId: String,
    val count: Int = 0,
)

val rand = Random(Clock.System.now().toEpochMilliseconds())

@FlowPreview
@ExperimentalCoroutinesApi
suspend fun runStressDevice(fbApp: FirebaseApp, dev: GenericDevice) {
    println("start Device: ${dev}")
    val db = Firebase.firestore(fbApp)
    val devDocRef = db.collection("device").document(dev.id)
    devDocRef.collection("query")
        .where("devId", equalTo = dev.id)
        .where("result", equalTo = null)
        .snapshots.flatMapMerge {
            channelFlow { it.documents.forEach { offer(it.data<DevStressQuery>()) } }
        }.buffer(10).collect { query ->
            println("Start Query: ${query.id}")
            repeat(query.schedule.limit) {
                inline fun <reified T> DocumentSnapshot.dataOrDefault(d: T) = if (exists) data() else d
                //db.runTransaction {
                val cDocRef = devDocRef.collection("counter").document("logs_${rand.nextInt(10)}")
                val c = cDocRef.get().dataOrDefault(Count(count = 0, devId = dev.id)).count
                println("Count=$c") //TODO
                cDocRef.set(Count.serializer(), Count(devId = dev.id, count = c + 1))
                devDocRef.collection("logs").add(
                    DevLog.serializer(), DevLog(
                        devId = dev.id,
                        cluster = dev.cluster,
                        time = Clock.System.now().toEpochMilliseconds().toInt(),
                    )
                )
                //}
                delay(query.schedule.interval)
            }
            devDocRef.collection("counter").snapshots.collect {
                val sum = it.documents.map { it.data<Count>().count }.sum()
                println("Sum: $sum")
            }

            println("End Query: ${query.id}")
        }
}


