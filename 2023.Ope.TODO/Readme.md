MFP操作WebUI - democode
=====



環境
---

- Ubuntu 22.04
- openjdk-17-jdk


Components
---

- Google Firestore
- Jetpack Compose for Web
- Kotlin/Wasm


## Project履歴




## チュートリアル: Jetpack Kotlin公式サンプルコード

Web向けビルドと実行
```sh
git clone --depth 1 https://github.com/Kotlin/kotlin-wasm-examples
cd kotlin-wasm-examples/compose-imageviewer
./gradlew :webApp:wasmJsRun
```
`http://localhost:8080`を開く
