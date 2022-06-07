# 環境
- OS: Windows 10/11
- Flutter: 3.0
 
# 開発環境設定

- [Flutter SDK - Install](https://docs.flutter.dev/get-started/install)
  - snapdの場合: `sudo snap install flutter --classic`
  - gitの場合: 
    ```
    git clone --depth 1 https://github.com/flutter/flutter.git
    export PATH="$PATH:`pwd`/flutter/bin"
    ```
- VSCode
  - Plugin > Remode Development Plugin(Remote WSL Plugin) - install
  - Plugin > Flutter plugin - Install
  - Dart plugin > 拡張機能の設定 > Flutter SDK path/ Dart SDK path - setup 
  - 実行 > 構成の追加 > Flutter:launch
  
  
# デバッグ実行
```
flutter doctor
flutter pub get
flutter run -d chrome
```
or
VSCodeでF5(デバッグ実行)

# プロジェクト作成履歴

- Firebase/Firestore プロジェクト(例:`road-to-iot`)作成(略)
- [Flutter アプリに Firebase を追加する](https://firebase.google.com/docs/flutter/setup)
  - firebase login
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

