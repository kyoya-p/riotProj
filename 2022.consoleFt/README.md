# 環境
- OS: Windows 10/11
- Flutter: 3.0
 
# 開発環境設定

- [Flutter SDK - Install](https://docs.flutter.dev/get-started/install)
- Firebase Tools
- VSCode
  - Plugin > Flutter plugin - Install
  - Dart plugin > 拡張機能の設定 > Flutter SDK path/ Dart SDK path - setup 
  - 実行 > 構成の追加 > Flutter:launch  //commit済


## ビルド
```
flutter pub get                     
flutter pub run build_runner build // freezed等でコード生成が必要な場合。常時チェックなら build=>watch
or
flutter build web
```
or VSCodeなら「ビルドタスクの実行」 (Ctrl+Shift+B)

`build/web` 以下に生成される

## デバッグ/実行
```
flutter run -d chrome
or 
flutter run --release -d chrome
```
or VSCodeなら「デバッグ実行」(F5)

## テストのためローカルデプロイ
```
firebase emulators:start
```
`http://localhost:4000/firestore ` を開き、Hostingなら、`http://localhost:5000/`をクリック

## Firebas Hostingでインターネットにデプロイ
```
flutter build web
firebase deploy
```

```:Preview版としてクラウドにデプロイ
firebase hosting:channel:deploy preview_name
```
Note: Previewはデフォルト1weekで停止

```:Hostingでのデプロイを停止したい場合
firebase hosting:disable
```
Note: previewは機能し続けるようだ

# プロジェクト作成履歴

- Firebase/Firestore プロジェクト(例:`road-to-iot`)作成(略)
- [Flutter アプリに Firebase を追加する](https://firebase.google.com/docs/flutter/setup)
  - npm install -g firebase-tools  // Firebase Tools導入
  - firebase login
  - firebase init    // Firestoreをチェック
  - firebase init hosting //  public directory = build/web
  - flutterfire configure --out lib/firebase_options.dart --project road-to-iot
  - main.dart に追記
    - `import 'firebase_options.dart'; `
    - `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);`

# 参考
- [【Flutter】iOS/Android/WebでFirebase Firestoreを使えるようにする](https://qiita.com/yoshikoba/items/1cfcda5b9f33555a113a)

---

# console_ft

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

