//const functions = require('firebase-functions');

//exports.helloWorld = functions.https.onRequest((request, response) => {
//  functions.logger.info("Hello logs!", {structuredData: true});
//  response.send("Hello from Firebase XXXX!");
//});


const functions = require('firebase-functions')
// cloud functionでfirestoreを使うのに必要な設定は以下の２行
const admin = require('firebase-admin')
admin.initializeApp(functions.config().firebase)

// データベースの参照を作成
var fireStore = admin.firestore()

exports.helloWorld = functions.https.onRequest((request, response) => {
  // 動作確認のため適当なデータをデータベースに保存
  var citiesRef = fireStore.collection('cities');
  citiesRef.doc('SF').set({
    name: 'San Francisco', state: 'CA', country: 'USA',
    capital: false, population: 860000 })

  var cityRef = fireStore.collection('cities').doc('SF')
  cityRef.get()
  .then(doc => {
    if (!doc.exists) {
      response.send('No such document!')
    } else {
      response.send(doc.data())
      }
    })
    .catch(err => {
      response.send('not found')
    })
})
