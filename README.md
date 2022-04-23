Project Road to IoT
====

Initiate Firebase 
----
```
firebase init firestore
```
以下生成される

- .firebaserc
- firebase.json
- firestore.indexes.json
- firestore.rules


Ruleのdeploy
```
firebase deploy --only firestore:rules
```