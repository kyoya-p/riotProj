UniAgent for node.js
====

Environment
----
- Java (for build)

```
git clone -d 1 https://github.com/kyoya-p/riotProj
cd UniAgent_ktJs
```

Build
----
```
./gradlew build
```

Run
----

``` 
[Linux]
node build/js/packages/fsAg_NodeKt/kotlin/fsAg_NodeKt.js deviceId 1234xxxx
[Windows]
node.exe RMM deviceId 1234xxxx
```
