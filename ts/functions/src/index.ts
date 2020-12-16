import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp(functions.config().firebase)
var firestore = admin.firestore()

export const helloWorld = functions.https.onRequest((request, response) => {
//  functions.logger.info("Hello logs!", {structuredData: true});
//  response.send("Hello from Firebase!");
    var citiesRef = firestore.collection('cities');
    citiesRef.doc('SF').set({
      name: 'San Francisco!!', state: 'CA', country: 'USA',
      capital: false, population: 860000 }).then(e=>void);

    var cityRef = firestore.collection('cities').doc('SF')
    cityRef.get().then(doc => {
      if (!doc.exists) {
        response.send('No such document!')
      } else {
        response.send(doc.data())
        }
      })
      .catch(err => {
        response.send('not found')
      })

});
