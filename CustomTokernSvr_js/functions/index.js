const functions = require('firebase-functions');

const admin = require('firebase-admin');
admin.initializeApp({serviceAccountId: 'firebase-adminsdk-rc191@road-to-iot.iam.gserviceaccount.com'});
var firestore = admin.firestore()

exports.requestToken = functions.https.onRequest((request, response) => {

    //response.set('Access-Control-Allow-Origin', 'https://road-to-iot.firebaseio.com');
    //response.set('Access-Control-Allow-Origin', 'http://localhost:8080');
    response.set('Access-Control-Allow-Origin', '*');
    response.set('Access-Control-Allow-Credentials', 'true');
    if (request.method === 'OPTIONS') {
        // Send response to OPTIONS requests
        // https://cloud.google.com/functions/docs/samples/functions-http-cors-auth?hl=ja#functions_http_cors_auth-nodejs
        response.set('Access-Control-Allow-Methods', 'GET');
        response.set('Access-Control-Allow-Headers', 'Authorization');
        response.set('Access-Control-Max-Age', '3600');
        response.status(204).send('');
    }

    var id=request.query.id; if(id==null) response.send("1");
    var pw=request.query.pw; if(pw==null) response.send("2");
    firestore.collection('device').doc(id).get().then(doc=>{
        if(doc==null) response.send("3");
        if(doc.data()==null) response.send("4");
        if(doc.data().dev==null) response.send("5.0");
        if(doc.data().cluster==null) response.send("5.1");
        if(doc.data().dev.password==null) response.send("6");
        if(pw!=doc.data().dev.password) response.send("7");
        var additionalClaims={id: id, cluster: doc.data().cluster};
        admin.auth().createCustomToken(id,additionalClaims)
            .then(customToken => {
                response.send(customToken);
            }).catch(error => {
                console.log('Error creating custom token:', error);
                response.send("8");
            });
    });
})

