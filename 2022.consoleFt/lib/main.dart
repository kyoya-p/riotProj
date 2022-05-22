import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Console',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const MyHomePage(title: 'Console'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    var db = FirebaseFirestore.instance;
    return Scaffold(
        appBar: AppBar(title: const Text("Console")),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.search),
          onPressed: () => {},
        ),
        body: Column(
          children: [
            TextField(decoration: InputDecoration(label: Text("Agent Id"))),
            TextField(decoration: InputDecoration(label: Text("Discovery IP"))),
            textViewer(db.doc("device/Agent1")),
            Expanded(child: TextField(minLines: 5, maxLines: null)),
          ],
        ));
  }
}

Widget textViewer<T>(DocumentReference<T> docRef) {
  return StreamBuilder<DocumentSnapshot>(
      stream: docRef.snapshots(),
      builder: (context, snapshot) {
        return Text(snapshot.data!.id);
      });
}
