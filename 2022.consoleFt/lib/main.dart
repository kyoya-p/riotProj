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
            const TextField(
                decoration: InputDecoration(label: Text("Agent Id"))),
            discoveryField(db.collection("device").doc("Agent1")),
            // discResultField(db
            //     .collection("device")
            //     .doc("Agent1")
            //     .collection("discResult")
            //     .doc("devices")),
            discResultField(db.collection("device/Agent1/discovery")),
          ],
        ));
  }
}

Widget discoveryField(DocumentReference docRefAg) {
  return StreamBuilder<DocumentSnapshot>(
      stream: docRefAg.snapshots(),
      builder: (context, snapshot) {
        var docAg = snapshot.data!.data()! as Map<String, dynamic>;
        var ipSpec = TextEditingController(text: docAg["ipSpec"] as String?);

        return TextField(
          controller: ipSpec,
          decoration: const InputDecoration(
            label: Text("Discovery IP"),
            hintText: "Ex: 1.2.3.1-1.2.3.254",
          ),
          onSubmitted: (ip) {
            docAg["ipSpec"] = ip;
            docRefAg.set(docAg);
          },
        );
      });
}

Widget discResultField(Query docRefResult) {
  return StreamBuilder<QuerySnapshot>(
      stream: docRefResult.snapshots(),
      builder: (context, snapshot) {
        var docDevs =
            snapshot.data?.docs.map((e) => e.data() as Map<String, dynamic>);
        if (docDevs == null) return loadingIcon();
        if (docDevs.length == 0) return noItems();
        return Text(docDevs.first["ip"]);
      });
}

Widget loadingIcon() => const Center(child: CircularProgressIndicator());
Widget noItems() => const Center(child: Text("No items"));
