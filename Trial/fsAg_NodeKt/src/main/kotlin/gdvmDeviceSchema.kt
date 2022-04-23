package gdvm.schema

import kotlinx.serialization.Serializable

typealias GdvmTime = Long
typealias GdvmObjectType = List<String>

// /device/{GdvmGenericDevice}
@Serializable
data class GenericDevice(
    // this is abstract definition for GDVM Object
    val id: String, // same as document.id
    val cluster: String,
    val type: GdvmObjectType = listOf("dev"),
    val time: GdvmTime, // create/update time in msec from epoch
    val dev: GdvmDeviceInfo,
)

@Serializable
data class Schedule(
    val start: Int = 0, // 0 = 1970/1/1 0:00 UTC
    val interval: Long = 0,
    val limit: Int = 1,
)

@Serializable
data class GdvmDeviceInfo(
    val password: String = "Sharp_#1",
) {
    companion object
}
