import 'dart:async';

import 'package:console_ft/vmstatChart.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'type.dart';
import 'vmstat.dart';

DocumentReference<Map<String, dynamic>>? refApp;
DocumentReference<Map<String, dynamic>>? refDev;

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final db = FirebaseFirestore.instance;
  refApp = db.collection("tmp").doc();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
                  timeRateIndicator(refDev!.collection("discovery")),
                  PopupMenuButton<String>(
                    initialValue: "",
                    onSelected: (String s) async {
                      if (s == "clear" && refDev != null) {
                        for (var e
                            in (await refDev!.collection("discovery").get())
                                .docs) {
                          e.reference.delete();
                        }
                      } else if (s == "vmstat") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const VmstatPage()),
                        );
                      } else if (s == "vmstatChart") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => VmstatChartPage()),
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        const PopupMenuItem(
                            value: "clear",
                            child: Text("Clear detected devices")),
                        const PopupMenuItem(
                            value: "vmstat", child: Text("vmstat")),
                        const PopupMenuItem(
                            value: "vmstatChart", child: Text("vmstat chart")),
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
                    child: discResultField(refDev!
                        .collection("discovery")
                        .orderBy("time", descending: true)
                        .limit(100))),
              ]));
        });
  }
}

Widget timeRateIndicator(
  Query<Map<String, dynamic>> refLogs,
) {
  Timer.periodic(const Duration(seconds: 1), (Timer t) => {});

  const nLog = 1;
  refLogs.orderBy("time", descending: true).limit(nLog);
  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: refLogs.snapshots(),
      builder: (context, snapshots) {
        final docsLog = snapshots.data?.docs;
        if (docsLog == null) return loadingIcon();
        if (docsLog.length < nLog) return noItem();
        final tNow = Timestamp.now();
        final t0 = docsLog.last.data()["time"] as Timestamp?;
        if (t0 == null) return loadingIcon();
        final td = tNow.millisecondsSinceEpoch - t0.millisecondsSinceEpoch;
        if (td == 0) return const Center(child: Text("-"));
        return Center(
            child: Text(
                '${tNow.seconds} > ${t0.seconds} = ${td / 1000} ${nLog * 1000.0 / td} /sec'));
      });
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
        final tecIpSpec =
            TextEditingController(text: docAg["ipSpec"] as String? ?? "");
        final tecInterval = TextEditingController(text: '${docAg["interval"]}');
        void updateDoc() {
          docAg["ipSpec"] = tecIpSpec.text;
          docAg["interval"] = int.parse(tecInterval.text);
          docRefAg.set(docAg);
        }

        return Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: TextField(
                controller: tecIpSpec,
                decoration: const InputDecoration(
                  label: Text("Scanning IP Range:"),
                  hintText: "スキャンIP範囲 例: 192.168.0.1-192.168.0.254",
                ),
                onSubmitted: (_) => updateDoc(),
              ),
            ),
            Expanded(
              child: TextField(
                controller: tecInterval,
                decoration: const InputDecoration(
                  label: Text("Interval:"),
                  hintText: "スキャンごとの間隔 ミリ秒単位",
                ),
                onSubmitted: (_) => updateDoc(),
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
            print(e);

            return ListTile(
              title: Text(
                  '${e["time"].toDate().toLocal()} : ${e["ip"]} : ${e["vbs"].join(" : ")}'),
            );
          },
        );
      });
}

class SnmpDiscResult {
  String ip = "";
}

Widget loadingIcon() => const Center(child: CircularProgressIndicator());
Widget noItem() => const Center(child: Text("No item"));

// Sample OID
const hrDeviceDescr = "1.3.6.1.2.1.25.3.2.1.3";
const hrDeviceStatus = "1.3.6.1.2.1.25.3.2.1.5";
const hrDeviceErrors = "1.3.6.1.2.1.25.3.2.1.6";
