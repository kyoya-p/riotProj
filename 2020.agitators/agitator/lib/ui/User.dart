// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_auth/firebase_auth.dart';

FirebaseFirestore db = FirebaseFirestore.instance;
User user = FirebaseAuth.instance.currentUser;

DocumentReference appData(String doc) =>
    db.collection("user").doc(user.uid).collection("app1").doc(doc);
