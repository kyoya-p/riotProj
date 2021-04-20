import com.google.cloud.firestore.FirestoreOptions
import gdvm.device.*
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import mibtool.snmp4jWrapper.*
import org.snmp4j.Snmp
import org.snmp4j.event.ResponseEvent
import org.snmp4j.smi.UdpAddress
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
    val dev = db.document("device/$deviceId").get().get().data?.toJsonObject()?.toObject<DeviceAgentMfpMib>()!!
    println("Start deviceId: ")
    db.collection("device/$deviceId/query")
        .whereEqualTo("cluster", "AgentStressTest").limit(3)
        .snapshotsAs<DeviceAgentMfpMib_Query>().collectLatest { queries ->
            println("Updated query:")// TODO
            queries.forEach { query ->
                scheduleFlow(query.schedule).collectLatest {
                    launch {
                        runAgentQuery(dev, query)
                    }
                }
            }
        }
}

@ExperimentalCoroutinesApi
suspend fun scheduleFlow(schedule: Schedule) = channelFlow {
    repeat(schedule.limit) { i ->
        offer(i)
        delay(schedule.interval) //TODO 不正確 要対応
    }
}

@ExperimentalCoroutinesApi
suspend fun runAgentQuery(dev: DeviceAgentMfpMib, query: DeviceAgentMfpMib_Query) {
    println("Start Query: device/${query.devId}/${query.id}")//TODO
    val reqOids = listOf(hrDeviceDescr, prtGeneralSerialNumber)
    query.scanAddrSpecs.asFlow().discoveryDeviceMap(snmp, reqOids).collect { res ->
        println("Res: ${res.peerAddress}")// TODO
        if (query.autoRegistration) {
            createDevice(dev, query, res)
        }
    }
    println("Terminate Query: device/${query.devId}/${query.id}")//TODO
}

fun createDevice(dev: DeviceAgentMfpMib, query: DeviceAgentMfpMib_Query, res: ResponseEvent<UdpAddress>) {
    val devId = res.response
    db.document("device/$devId").set(json{})
}