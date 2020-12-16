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


サービスアカウントに権限追加
----
* https://firebase.google.com/docs/auth/admin/create-custom-tokens?hl=ja

サービス アカウント ID を使用する
 - Google が管理する環境でこの方法を使用すると、指定したサービス アカウントのキーを使用してトークンに署名されます。 ただし、リモート ウェブサービスを使用するため、Google Cloud Platform Console でこのサービス アカウントに追加の権限を構成しなければならない場合があります。

https://console.cloud.google.com/identity/serviceaccounts?project=road-to-iot
firebase-adminsdk-rc191@road-to-iot.iam.gserviceaccount.com
に対して
- アカウントが有効であることを確認


