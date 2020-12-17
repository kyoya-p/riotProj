
const functions = require('firebase-functions');

const admin = require('firebase-admin');
//admin.initializeApp(functions.config().firebase);
admin.initializeApp({serviceAccountId: 'firebase-adminsdk-rc191@road-to-iot.iam.gserviceaccount.com'});

var firestore = admin.firestore()

exports.helloWorld = functions.https.onRequest((request, response) => {
    var id=request.query.id;
    var pw=request.query.pw;
    response.send(id+pw);
})

exports.firestoreTest = functions.https.onRequest((request, response) => {
  // 動作確認のため適当なデータをデータベースに保存
  var citiesRef = firestore.collection('cities');
  citiesRef.doc('SF').set({
    name: 'San Francisco!!', state: 'CA', country: 'USA',
    capital: false, population: 860000 })

  var cityRef = firestore.collection('cities').doc('SF')
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

exports.requestToken = functions.https.onRequest((request, response) => {
    var id=request.query.id; if(id==null) response.send("1//TODO:hideErrorInfo");
    var pw=request.query.pw; if(pw==null) response.send("2//TODO:hideErrorInfo");
    firestore.collection('device').doc(id).get().then(doc=>{
        if(doc==null) response.send("3a//TODO:hideErrorInfo")
        if(doc.data()==null) response.send("3b//TODO:hideErrorInfo")
        if(doc.data().dev==null) response.send("3c//TODO:hideErrorInfo")
        if(doc.data().dev.password==null) response.send("3d//TODO:hideErrorInfo")
        if(pw==doc.data().dev.password) {
            var additionalClaims={id: id, cluster: doc.data().dev.cluster};
            admin.auth().createCustomToken(id,additionalClaims)
                .then(customToken => {
                    response.send(customToken);
                }).catch(error => {
                    console.log('Error creating custom token:', error);
                    response.send("4//TODO:hideErrorInfo");
                });
        }else{
            response.send("5//TODO");
        }
    });
})

