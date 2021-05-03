plugins {
    application
    kotlin("jvm") version "1.4.32"
    kotlin("plugin.serialization") version "1.4.32"
}

val serializationVersion = "1.1.0" // https://mvnrepository.com/artifact/org.jetbrains.kotlinx/kotlinx-serialization

version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
    google()
}

dependencies {
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.3.1")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.1.0") // https://mvnrepository.com/artifact/org.jetbrains.kotlinx/kotlinx-serialization-json
    implementation("com.google.cloud:google-cloud-firestore:2.2.6") // https://mvnrepository.com/artifact/com.google.cloud/google-cloud-firestore

    implementation("org.snmp4j:snmp4j:3.4.4") // https://mvnrepository.com/artifact/org.snmp4j/snmp4j
}





