import com.google.cloud.firestore.FirestoreOptions
import gdvm.device.*
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import mibtool.snmp4jWrapper.*
import org.snmp4j.Snmp
import org.snmp4j.transport.DefaultUdpTransportMapping


// GOOGLE_APPLICATION_CREDENTIALS=//pathto/road-to-iot-8efd3bfb2ccd.json
val db = FirestoreOptions.getDefaultInstance().getService()
val snmp = Snmp(DefaultUdpTransportMapping().apply { listen() })

@ExperimentalCoroutinesApi
suspend fun main() {
    runAgent("stressAgent1", "1234eeee")
}

@ExperimentalCoroutinesApi
suspend fun runAgent(deviceId: String, secret: String) = coroutineScope {
    println("Start deviceId: ")
    db.collection("device").document(deviceId).collection("query")
        .whereEqualTo("cluster", "AgentStressTest").limit(3)
        .snapshotsAs<DeviceAgentMfpMib_Query>().collectLatest { queries ->
            println("Updated query:")// TODO
            queries.forEach { query -> scheduleFlow(query.schedule).collectLatest { launch { runAgentQuery(query) } } }
        }

}

@ExperimentalCoroutinesApi
suspend fun scheduleFlow(schedule: Schedule) = channelFlow {
    //val start = Date().time
    repeat(schedule.limit) { i ->
        offer(i)
        //val next = (Date().time / schedule.interval + 1) * schedule.interval
        delay(schedule.interval)
    }
}

suspend fun runAgentQuery(query: DeviceAgentMfpMib_Query) {
    println("Start Agent ${query}")//TODO
    query.scanAddrSpecs.asFlow().discoveryDeviceMap(snmp).collect { res ->
        println("Res: ${res.peerAddress}")// TODO
    }
    println("Terminate Agent ${query}")//TODO

}
