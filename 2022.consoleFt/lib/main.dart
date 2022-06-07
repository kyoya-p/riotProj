import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

DocumentReference<Map<String, dynamic>>? docRefAppTmpData;

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  var db = FirebaseFirestore.instance;
  docRefAppTmpData = db.collection("tmp").doc();
  docRefAppTmpData?.set({"ag": "Agent1"});
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Console',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
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
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRefAppTmpData?.snapshots(),
      builder: (context, snapshot) {
        final ag = snapshot.data?.data()?["ag"] as String;
        if (ag == null) return loadingIcon();
        return Scaffold(
            appBar: AppBar(title: const Text("Console")),
//            floatingActionButton: FloatingActionButton(
//                child: const Icon(Icons.search), onPressed: () => {}),
            body: Column(
              children: [
                TextField(decoration: InputDecoration(label: Text(ag))),
                discoveryField(db.collection("device").doc("Agent1")),
                discResultField(db.collection("device/Agent1/discovery")),
              ],
            ));
      },
    );
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
          onSubmitted: (ip) async {
            final ress = await docRefAg.collection("discovery").get();
            ress.docs.forEach((d) => d.reference.delete());
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
        final docDevs =
            snapshot.data?.docs.map((e) => e.data() as Map<String, dynamic>);
        if (docDevs == null) return loadingIcon();
        if (docDevs.isEmpty) return noItem();
        return Column(children: docDevs.map((e) => Text(e["ip"])).toList());
      });
}

class SnmpDiscResult {
  String ip = "";
}

class MIB {}

Widget loadingIcon() => const Center(child: CircularProgressIndicator());
Widget noItem() => const Center(child: Text("No item"));

// Sample OID
const hrDeviceDescr = "1.3.6.1.2.1.25.3.2.1.3";
const hrDeviceStatus = "1.3.6.1.2.1.25.3.2.1.5";
const hrDeviceErrors = "1.3.6.1.2.1.25.3.2.1.6";
