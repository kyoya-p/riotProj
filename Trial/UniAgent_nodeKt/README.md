UniAgent for node.js
====

Environment
----
- Java

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
./gradlew runUniAgent
```
see: "runUniAgent" task in file 'build.gradle.kts'.

or
``` 
[Linux]
.gradle/nodejs/node-v12.18.3-linux-x64/bin/node build/js/packages/UniAgent/kotlin/UniAgent.js MetaAgent1 1234xxxx
[Windows]
.gradle/nodejs/node-v12.18.3-win-x64/node.exe build/js/packages/UniAgent/kotlin/UniAgent.js MetaAgent1 1234xxxx
```
