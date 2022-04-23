import 'package:cloud_firestore/cloud_firestore.dart';

Stream<QuerySnapshot> getDevLogStream() {
  return FirebaseFirestore.instance.collection("devLogs").snapshots();
}


