Node.js / Typescript / VSCode / WSL
===

### 環境
- Ubuntu 20.04 on WSL / Windows
- node.js
- npm
- VSCode / Remote Development plugin

### ビルド
```
npm update
npx tsc
```

##### 開発環境設定
- Windows に VSCode 導入
- VSCode上で Ctrl+Shift+P > Remote-WSL:New WSL Window
- VSCode上でターゲットフォルダを開き、Terminal を開き操作

#### ビルド/開発環境設定

```
sudo apt install -y nodejs
sudo apt install -y npm
```
※ 「HTTP proxy を使用する場合」 参照

#### ビルド
```
npm update
npx tsc
```

### 実行
node build/index.js

### VSCodeで実行
- .vscode/launch.json を編集
- Ctrl+F5

### プロジェクト作成記録
※「Firestore Mobile SDK for Web 準備」参照
```
npm init       // packages.json 作成
npm install --save typescript @types/node@12
npx tsc --init // tsconfig.js調整 - outDir 設定等 
npx firebase init  // ※参照: Firestore Mobile SDK for Web 準備
               // Firestore,Functions, Emulators 機能を有効化
               // Use an existing project (既存projectの場合)
               // project-id: road-to-iot (既存project名)
               // 言語: TypeScript / ESLint:無し
npm install --save @firebase/app
npm install --save @firebase/firestore
```

#### [Firestore Mobile SDK for Web 準備](https://firebase.google.com/codelabs/firestore-web?hl=ja#0)
```
npm install firebase-tools
npx firebase --version
npx firebase login              // ブラウザで認証後、firebase使用を承認する
```


### npmでHTTP proxy を使用する場合
```
proxy_cred=${proxy_user}:${proxy_password}@
npm config set proxy http://${proxy_cred}${proxy_host}:${proxy_port}
npm config set https-proxy http://${proxy_cred}${proxy_host}:${proxy_port}
npm config set registry https://registry.npmjs.org/
npm config set strict-ssl false
```

```
export http_proxy=http://${proxy_cred}${proxy_host}:${proxy_port}
```

### 参考
1. [Firestore Quickstart](https://cloud.google.com/firestore/docs/quickstarts?hl=ja-JP)
2. [Firestore Mobile SDK](https://cloud.google.com/firestore/docs/create-database-web-mobile-client-library?hl=ja-JP)
3. [Firestore Quickstart Usage](https://firebase.google.com/docs/firestore/quickstart?hl=ja)

- [API Reference - Mobile Web SDK](https://firebase.google.com/docs/reference/js/firestore_)
- [VSCode with WSL](https://code.visualstudio.com/docs/remote/wsl#_questions-or-feedback)
- [Net-SNMP for node.js Sample](https://github.com/kyoya-p/samples/tree/c99ef504849982d5238ea0e53916bdd95eedb349/2020/fsJsAgent)
- [Firebase SDK v9](https://qiita.com/mogmet/items/23d4ee734f4b193b8106)

- [マコちゃんのProxyチートシート](https://qiita.com/Makotunes/items/1c2aab00813a0b58bb9b)
