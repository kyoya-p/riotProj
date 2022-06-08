import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

DocumentReference<Map<String, dynamic>>? refApp;

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  var db = FirebaseFirestore.instance;
  refApp = db.collection("tmp").doc();
  //refApp?.set({"ag": "agent"});
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
      stream: refApp?.snapshots(),
      builder: (context, snapshot) {
        final ag = snapshot.data?.data()?["ag"] as String? ?? "No Agent";
        return Scaffold(
            appBar: AppBar(title: Text("$ag - Console")),
//            floatingActionButton: FloatingActionButton(
//                child: const Icon(Icons.search), onPressed: () => {}),
            body: Column(
              children: [
                agentNameField(refApp!),
                discoveryField(db.collection("d").doc(ag)),
                discResultField(db.collection("d").doc(ag).collection("discovery")),
              ],
            ));
      },
    );
  }
}

Widget agentNameField(DocumentReference<Map<String, dynamic>> refApp) {
  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: refApp.snapshots(),
      builder: (context, snapshot) {
        var docApp = snapshot.data?.data() ?? {} ;
        var agId = TextEditingController(text: docApp["ag"] as String? ?? "");
        return TextField(
          controller: agId,
          decoration: const InputDecoration(label: Text("Agent ID:")),
          onSubmitted: (ag) async {
            docApp["ag"] = ag;
            refApp.set(docApp);
          },
        );
      });
}

Widget discoveryField(DocumentReference<Map<String, dynamic>> docRefAg) {
  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRefAg.snapshots(),
      builder: (context, snapshot) {
        final docAg = snapshot.data?.data() ??  {};
        final ipSpec = docAg["ipSpec"] as String?  ?? "";
        return TextField(
          controller: TextEditingController(text: ipSpec),
          decoration: const InputDecoration(
            label: Text("Discovery IP:"),
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
        return Column(
            children: docDevs
                .map((e) =>
                    Text(e["ip"] + " : " + e["vbs"].join(" : ") + e["err"]))
                .toList());
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
