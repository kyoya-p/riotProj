plugins {
    kotlin("js") version "1.4.31"
    kotlin("plugin.serialization") version "1.4.31"
    id("com.github.node-gradle.node") version "3.0.0-rc5"
}

group = "org.example"
version = "1.0-SNAPSHOT"
val coroutine_version = "1.4.3"
val serialization_version = "1.1.0"

repositories {
    mavenCentral()
    jcenter()
}

dependencies {
    implementation(kotlin("stdlib-js"))
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:$coroutine_version") // https://mvnrepository.com/artifact/org.jetbrains.kotlinx/kotlinx-coroutines-android
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:$serialization_version") // https://mvnrepository.com/artifact/org.jetbrains.kotlinx/kotlinx-serialization-core
    implementation("org.jetbrains.kotlinx:kotlinx-nodejs:0.0.7") // https://mvnrepository.com/artifact/org.jetbrains.kotlinx/kotlinx-nodejs
    implementation("io.ktor:ktor-client-core:1.5.2") // https://mvnrepository.com/artifact/io.ktor/ktor-client-cio

    implementation("dev.gitlive:firebase-auth:1.2.0") // https://mvnrepository.com/artifact/dev.gitlive/firebase-auth
    implementation("dev.gitlive:firebase-firestore:1.2.0") // https://mvnrepository.com/artifact/dev.gitlive/firebase-firestore
}

kotlin {
    js {
        nodejs { }
        // browser()
        binaries.executable()
    }
}