Firebase Cloud Functions
====

Setup
----
```
curl -sL https://firebase.tools | bash
firebase login
```
* ブラウザを勝手に開くのでログインする。ブラウザを開けない環境ならciモードで。
  https://firebase.google.com/docs/cli?hl=ja

* firebase-tools upgrade:  
`sudo npm install -g firebase-tools`
  
*  npm も upgradeが必要なら...  
`sudo apt upgrade`
   


```
firebase init

     ######## #### ########  ######## ########     ###     ######  ########
     ##        ##  ##     ## ##       ##     ##  ##   ##  ##       ##
     ######    ##  ########  ######   ########  #########  ######  ######
     ##        ##  ##    ##  ##       ##     ## ##     ##       ## ##
     ##       #### ##     ## ######## ########  ##     ##  ######  ########

You're about to initialize a Firebase project in this directory:

  /mnt/c/works/riotProj

Before we get started, keep in mind:

  * You are currently outside your home directory
  * You are initializing in an existing Firebase project directory

? Which Firebase CLI features do you want to set up for this folder? Press Space to select features, then Enter to confirm your choices. (Press <space> to select, <a> to toggle all, <i> to invert
 selection)
❯◯ Database: Configure Firebase Realtime Database and deploy rules
 ◯ Firestore: Deploy rules and create indexes for Firestore
 ◯ Functions: Configure and deploy Cloud Functions
 ◯ Hosting: Configure and deploy Firebase Hosting sites
 ◯ Storage: Deploy Cloud Storage security rules
 ◯ Emulators: Set up local emulators for Firebase features
 ◯ Remote Config: Get, deploy, and rollback configurations for Remote Config
 ```

* 使用するFirebaseの機能を選択 ここではFunctions
* Firebaseプロジェクトを選択
* 言語を選択 ここではTypescript

Deploy
----
init で生成されたスケルトンコードを編集
```funtions/src/index.ts
import * as functions from 'firebase-functions';

// Start writing Firebase Functions
// https://firebase.google.com/docs/functions/typescript

export const helloWorld = functions.https.onRequest((request, response) => {
  functions.logger.info("Hello logs!", {structuredData: true});
  response.send("Hello from Firebase!");
});
```

```
firebase deploy
```
URLが表示されるのでアクセスし上記が表示されることを確認。




