import com.github.gradle.node.task.NodeTask

val kotlinVersion = "1.4.30"
val serializationVersion = "1.0.0-RC"
val ktorVersion = "1.5.1"

plugins {
    kotlin("multiplatform") version "1.4.0"
    application //to run JVM part
    kotlin("plugin.serialization") version "1.4.30"
    id("com.github.node-gradle.node") version "3.0.0-rc5"
}

group = "org.example"
version = "1.0-SNAPSHOT"

node {
    version.set("12.18.3")
    download.set(true)
    useGradleProxySettings.set(true)
}

repositories {
    maven { setUrl("https://dl.bintray.com/kotlin/kotlin-eap") }
    mavenCentral()
    jcenter()
    maven("https://kotlin.bintray.com/kotlin-js-wrappers/") // react, styled, ...
    maven("https://kotlin.bintray.com/kotlinx/")
}


kotlin {
    //jvm { withJava() }
    js {
        nodejs {}
    }
    sourceSets {
        val commonMain by getting {
            dependencies {
                implementation(kotlin("stdlib-common"))
                implementation("org.jetbrains.kotlinx:kotlinx-serialization-core:$serializationVersion")
                implementation("io.ktor:ktor-client-core:$ktorVersion")
                implementation("org.jetbrains.kotlinx:kotlinx-datetime:0.1.1")
            }
        }
        val commonTest by getting {
            dependencies {
                implementation(kotlin("test-common"))
                implementation(kotlin("test-annotations-common"))
            }
        }

/*        val jvmMain by getting {
            dependencies {
                implementation("io.ktor:ktor-serialization:$ktorVersion") // https://mvnrepository.com/artifact/io.ktor/ktor-client-serialization
                implementation("io.ktor:ktor-server-core:$ktorVersion") // https://mvnrepository.com/artifact/io.ktor/ktor-server-core
                implementation("io.ktor:ktor-server-netty:$ktorVersion")
                implementation("io.ktor:ktor-websockets:$ktorVersion")
                implementation("ch.qos.logback:logback-classic:1.2.3")
                implementation("org.litote.kmongo:kmongo-coroutine-serialization:4.1.1")
            }
        }

 */

        val jsMain by getting {
            dependencies {
                implementation(npm("firebase", "8.2.6")) // https://www.npmjs.com/package/firebase
                implementation(npm("net-snmp", "2.10.1"))
                implementation(npm("global-agent", "2.1.12"))
                implementation("org.jetbrains.kotlinx:kotlinx-datetime:0.1.1")
            }
        }
    }
}

application {
    mainClassName = "ServerKt"
}

// include JS artifacts in any JAR we generate
/*tasks.getByName<Jar>("jvmJar") {
    val taskName = if (project.hasProperty("isProduction")) {
        "jsBrowserProductionWebpack"
    } else {
        "jsBrowserDevelopmentWebpack"
    }
    val webpackTask = tasks.getByName<KotlinWebpack>(taskName)
    dependsOn(webpackTask) // make sure JS gets compiled first
    from(File(webpackTask.destinationDirectory, webpackTask.outputFileName)) // bring output file along into the JAR
}

 */

tasks {
    withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
        kotlinOptions {
            jvmTarget = "1.8"
        }
    }
}

distributions {
    main {
        contents {
            from("$buildDir/libs") {
                rename("${rootProject.name}-jvm", rootProject.name)
                into("lib")
            }
        }
    }
}

// Alias "installDist" as "stage" (for cloud providers)
tasks.create("stage") {
    dependsOn(tasks.getByName("installDist"))
}

tasks.getByName<JavaExec>("run") {
    classpath(tasks.getByName<Jar>("jvmJar")) // so that the JS artifacts generated by `jvmJar` can be found and served
}

tasks.register<Zip>("zipPackage") {
    dependsOn(tasks.build, tasks.nodeSetup)

    //destinationDirectory.set(file(".."))
    archiveFileName.set("uniAgent.zip")

    //from("build/js", ".gradle/nodejs")
    from(".gradle/nodejs", "build/js")
}


tasks.register<NodeTask>("runUniAgent") {
    dependsOn(tasks.build, tasks.nodeSetup)
    script.set(file("build/js/packages/UniAgent/kotlin/UniAgent.js"))
    args.set(listOf("MetaAgent1", "1234xxxx"))
}

tasks.register<NodeTask>("run_0_SnmpDevice") {
    dependsOn(tasks.build, tasks.nodeSetup)
    script.set(file("build/js/packages/UniAgent/kotlin/UniAgent.js"))
    args.set(listOf("0_SnmpDevice", "1234xxxx"))
}

tasks.register<NodeTask>("runUniAgent_agent") {
    val PROXY = "http://proxyjp5.sharp.co.jp:3080"

    //val PROXY = "http://admin:admin@172.29.241.32:807"
    val proxySettings = mapOf(
        "GLOBAL_AGENT_HTTP_PROXY=" to PROXY,
        "GLOBAL_AGENT_HTTPS_PROXY=" to PROXY,
        "http_proxy=" to PROXY,
        "https_proxy=" to PROXY
    )

    dependsOn(tasks.build, tasks.nodeSetup)
    script.set(file("build/js/packages/UniAgent/kotlin/UniAgent.js"))
    args.set(listOf("snmpDevice1", "Sharp_#1"))
    environment.putAll(proxySettings)
}
