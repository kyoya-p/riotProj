import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

DocumentReference<Map<String, dynamic>>? refApp;
DocumentReference<Map<String, dynamic>>? refDev;

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final db = FirebaseFirestore.instance;
  refApp = db.collection("tmp").doc();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Console',
      theme: ThemeData(primarySwatch: Colors.orange),
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
          final ag = snapshot.data?.data()?["ag"] as String? ?? "default";
          refDev = db.collection("d").doc(ag);
          return Scaffold(
              appBar: AppBar(
                title: Text("$ag - Console"),
                actions: [
                  PopupMenuButton<String>(
                    initialValue: "",
                    onSelected: (String s) {
                      // setState(() {
                      //   //_selectedValue = s;
                      // });
                      if (s == "clear") {
                        refDev?.collection("discovery");
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        const PopupMenuItem(
                            value: "clear",
                            child: Text("Clear detected devices"))
                      ];
                    },
                  ),
                ],
              ),
//            floatingActionButton: FloatingActionButton(
//                child: const Icon(Icons.search), onPressed: () => {}),
              body: Column(children: [
                agentNameField(refApp!),
                discField(refDev!),
                Expanded(
                    child: discResultField(refDev!.collection("discovery"))),
              ]));
        });
  }
}

Widget agentNameField(DocumentReference<Map<String, dynamic>> refApp) {
  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: refApp.snapshots(),
      builder: (context, snapshot) {
        var docApp = snapshot.data?.data() ?? {};
        //var agId = TextEditingController(text: docApp["ag"] as String? ?? "default");
        return TextField(
          controller:
              TextEditingController(text: docApp["ag"] as String? ?? "default"),
          decoration: const InputDecoration(label: Text("Agent ID:")),
          onSubmitted: (ag) async {
            docApp["ag"] = ag;
            refApp.set(docApp);
          },
        );
      });
}

Widget discField(DocumentReference<Map<String, dynamic>> docRefAg) {
  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRefAg.snapshots(),
      builder: (context, snapshot) {
        final docAg = snapshot.data?.data() ?? {};
        final ipSpec = docAg["ipSpec"] as String? ?? "";
        return Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: TextField(
                controller: TextEditingController(
                    text: docAg["ipSpec"] as String? ?? ""),
                decoration: const InputDecoration(
                  label: Text("Scanning IP Range:"),
                  hintText: "スキャンIP範囲 例: 192.168.0.1-192.168.0.254",
                ),
                onSubmitted: (ip) async {
                  // final ress = await docRefAg.collection("discovery").get();
                  // for (var d in ress.docs) {
                  //   d.reference.delete();
                  // }
                  docAg["ipSpec"] = ip;
                  docRefAg.set(docAg);
                },
              ),
            ),
            Expanded(
              child: TextField(
                controller: TextEditingController(
                    text: (docAg["interval"] as int? ?? 1000).toString()),
                decoration: const InputDecoration(
                  label: Text("Interval:"),
                  hintText: "スキャンごとの間隔 ミリ秒単位",
                ),
                onSubmitted: (ip) async {
                  final ress = await docRefAg.collection("discovery").get();
                  for (var d in ress.docs) {
                    d.reference.delete();
                  }
                  docAg["ipSpec"] = ip;
                  docRefAg.set(docAg);
                },
              ),
            ),
          ],
        );
      });
}

Widget discResultField(Query docRefResult) {
  return StreamBuilder<QuerySnapshot>(
      stream: docRefResult.snapshots(),
      builder: (context, snapshot) {
        final docDevs = snapshot.data?.docs
            .map((e) => e.data() as Map<String, dynamic>)
            .toList();
        if (docDevs == null) return loadingIcon();
        if (docDevs.isEmpty) return noItem();
        return ListView.builder(
          scrollDirection: Axis.vertical,
          itemCount: docDevs.length,
          itemBuilder: (context, index) {
            final e = docDevs[index];
            return ListTile(
                title: Text(e["ip"] + " : " + e["vbs"].join(" : ") + e["err"]));
          },
        );
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
