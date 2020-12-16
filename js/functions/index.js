
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
    var id=request.query.id;
    var pw=request.query.pw;

    firestore.collection('device').doc(id).get().then(doc=>{
        if(pw==doc.data().dev.password) {
            var additionalClaims={id: id, cluster: doc.data().dev.cluster};
            admin.auth().createCustomToken(id,additionalClaims)
                            .then(function(customToken) {
                                response.send("customToken");
                            }).catch(function(error) {
                                //console.log('Error creating custom token:', error);
                                response.send(error);
                            });

                            //response.send(additionalClaims);
        }else{
            //console.log('Error creating custom token:', error);
            response.send("err");
        }
    });

})
