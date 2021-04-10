plugins {
    kotlin("js") version "1.4.32" // https://plugins.gradle.org/plugin/org.jetbrains.kotlin.js
    kotlin("plugin.serialization") version "1.4.32" //https://plugins.gradle.org/plugin/org.jetbrains.kotlin.plugin.serialization
    //id("com.github.node-gradle.node") version "3.0.1" //https://plugins.gradle.org/plugin/com.github.node-gradle.node
}

group = "org.example"
version = "1.0-SNAPSHOT"

repositories {
    jcenter()
    mavenCentral()
    maven { setUrl("firebase-kotlin-sdk") }
}

dependencies {
    implementation(kotlin("stdlib-js"))
    //implementation("org.jetbrains.kotlinx:kotlinx-nodejs:0.0.7") // https://mvnrepository.com/artifact/org.jetbrains.kotlinx/kotlinx-nodejs?repo=kotlinx

    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.1.0") // https://mvnrepository.com/artifact/org.jetbrains.kotlin/kotlin-serialization
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.4.3") // https://mvnrepository.com/artifact/org.jetbrains.kotlinx/kotlinx-coroutines-core
    implementation("io.ktor:ktor-client-core:1.5.3") // https://mvnrepository.com/artifact/io.ktor/ktor-client-core
    implementation("org.jetbrains.kotlinx:kotlinx-datetime:0.1.1") // https://mvnrepository.com/artifact/org.jetbrains.kotlinx/kotlinx-datetime

    implementation("dev.gitlive:firebase-auth:1.2.0") // https://mvnrepository.com/artifact/dev.gitlive/firebase-auth
    implementation("dev.gitlive:firebase-firestore:1.2.0") // https://mvnrepository.com/artifact/dev.gitlive/firebase-firestore

    //implementation(npm("firebase", "8.2.6")) // https://www.npmjs.com/package/firebase
    //implementation(npm("net-snmp", "2.10.1")) // https://www.npmjs.com/package/net-snmp
    //implementation(npm("global-agent", "2.1.12")) // https://www.npmjs.com/package/global-agent

}

kotlin {
    js {
        nodejs {
        }
        binaries.executable()
    }
}