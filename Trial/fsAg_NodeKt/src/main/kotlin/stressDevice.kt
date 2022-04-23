import dev.gitlive.firebase.Firebase
import dev.gitlive.firebase.FirebaseApp
import dev.gitlive.firebase.firestore.*
import gdvm.schema.GenericDevice
import gdvm.schema.Schedule
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import kotlinx.datetime.Clock
import kotlinx.serialization.Serializable
import kotlin.random.Random

@Serializable
data class DevStressQuery(
    val id: String,
    val cluster: String,
    val devId: String,
    val time: Long = 0, // time
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

    val cList = mutableMapOf<String, Int>()
    devDocRef.collection("query")
        .where("devId", equalTo = dev.id)
        .where("result", equalTo = null)
        .snapshots.flatMapMerge {
            channelFlow { it.documents.forEach { offer(it.data<DevStressQuery>()) } }
        }.buffer(10).collect { query ->
            println("Start Query: ${query.id}")
            val st = Clock.System.now().toEpochMilliseconds()
            (0 until query.schedule.limit).map {
                val j = GlobalScope.launch {
                    val t1 = Clock.System.now().toEpochMilliseconds()
                    db.runTransaction {
                        val t2 = Clock.System.now().toEpochMilliseconds()
                        val cName = "logs_${rand.nextInt(100)}"
                        val cDocRef = devDocRef.collection("counter").document(cName)
                        launch {
                            val c = cDocRef.get().dataOrDefault(Count(count = 0, devId = dev.id)).count + 1
                            cDocRef.set(Count.serializer(), Count(devId = dev.id, count = c))
                            cList[cName] = c
                            val sum = cList.map { it.value }.sum()
                            val t3 = Clock.System.now().toEpochMilliseconds()
                            println("$cName=${cList[cName]} sum=$sum : t1:${t1 - st} t2-t1:${t2 - t1} t3-t2:${t3 - t2}") //TODO
                        }
                        devDocRef.collection("logs").add(
                            DevLog.serializer(), DevLog(
                                devId = dev.id,
                                cluster = dev.cluster,
                                time = (t1 / 1000).toInt()
                            )
                        )
                    }
                }
                delay(query.schedule.interval)
                j
            }.toList().forEach { it.join() }
            val sum = devDocRef.collection("counter").get().documents.sumOf { it.data<Count>().count }
            println("Sum: $sum")
            println("End Query: ${(Clock.System.now().toEpochMilliseconds() - st) / 1000.0} :${query.id}")
        }
}

inline fun <reified T> DocumentSnapshot.dataOrDefault(d: T) = if (exists) data() else d





