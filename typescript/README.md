Firebase Cloud Functions ~ Typescript
====

Setup
----

*   必要ならnpm更新から 
```
sudo apt update
sudo apt -y upgrade
sudo apt install -y npm   
```


```
curl -sL https://firebase.tools | bash
firebase login
```
* ブラウザを勝手に開くのでログインする。ブラウザを開けない環境なら `firebase login:ci`。
  https://firebase.google.com/docs/cli?hl=ja

```
firebase init
```

* 使用するFirebaseの機能を選択 (ここではFunctions)
* Firebaseプロジェクトを選択
* 言語を選択 ここではTypescript

Deploy
----
```
firebase deploy
```

1. `https://console.cloud.google.com/functions` を開く
2. `helloWorld`のトリガーURLを確認し開く






