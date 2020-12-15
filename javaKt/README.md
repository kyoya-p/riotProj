Firebase Cloud Functions ~ Java/Kotlin
====
https://cloud.google.com/functions/docs/quickstart-java


Cloud SDK Setup
----
https://cloud.google.com/sdk/docs

```
sudo apt install -y python3
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-319.0.0-linux-x86_64.tar.gz
tar xvf google-cloud-sdk-319.0.0-linux-x86_64.tar.gz
./google-cloud-sdk/install.sh
```
シェル再起動

projectのdirectoryに移動し
```
gcloud init
```

Browser開きログインし、token入手  
入手したtokenをプロンプトに入力

プロジェクトを指定
Region指定

JDK install
```
sudo apt install -y openjdk-11-jdk
```

コーディング・ビルド・デプロイ
----
https://cloud.google.com/functions/docs/first-java
関数本体コードとbuild.gradleを生成
```
gcloud functions deploy my-first-function --entry-point HelloWorld --runtime java11 --trigger-http --memory 512MB --allow-unauthenticated
```

~ Kotlinコード
----
https://codenerve.com/creating-google-cloud-functions-in-kotlin/index.html

```build.gradle
buildscript {
    ext.kotlin_version = '1.4.10'
    repositories {
        mavenLocal()
        jcenter()
        google()
    }
    dependencies {
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}

apply plugin: 'kotlin'
```

```hello.kt
package functions

import com.google.cloud.functions.HttpFunction
import java.io.BufferedWriter
import java.io.IOException

class HelloWorldKt : HttpFunction {
    // Simple function to return "Hello World"
    @Throws(IOException::class)
    override fun service(request: com.google.cloud.functions.HttpRequest, response: com.google.cloud.functions.HttpResponse) {
        val writer: BufferedWriter = response.getWriter()
        writer.write("Hello Kt World! ")
    }
}
```

```
gcloud functions deploy my-first-function --entry-point HelloWorldKt --runtime java11 --trigger-http --memory 512MB --allow-unauthenticated
```

~ Uber (Fat) jarによるデプロイ
----
https://cloud.google.com/functions/docs/concepts/java-deploy?hl=ja

```build.gradle
buildscript {
   repositories {
       jcenter()
   }
   dependencies {
       ...
       classpath "com.github.jengelman.gradle.plugins:shadow:5.2.0"
   }
}

plugins {
   id 'java'
   ...
}
sourceCompatibility = '11.0'
targetCompatibility = '11.0'
apply plugin: 'com.github.johnrengelman.shadow'

shadowJar {
   mergeServiceFiles()
}
```

```
gradle shadowJar
```

```
gcloud functions deploy createToken --entry-point=functions.reqestToken --runtime=java11 --trigger-http --source=build/libs --allow-unauthenticated
```

```Browser
https://us-central1-road-to-iot.cloudfunctions.net/createToken?id=123&pw=111
```

~ Firebase Java Admin SDK を使用してデプロイ
----
https://firebase.google.com/docs/libraries?hl=ja
https://firebase.google.com/docs/admin/setup?hl=ja

* Firebase SDKを使用してCloud FinctionsにデプロイすればFirestoreクレデンシャルを自動で提供してくれる


Firebase SDK Setup
```
apt install -y npm
npm install -g firebase-tools
```
