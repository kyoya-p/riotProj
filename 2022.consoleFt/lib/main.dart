import 'dart:async';

import 'package:console_ft/metrics_chart.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'snmp.dart';
import 'types.dart';
import 'log_viewer.dart';

final db = FirebaseFirestore.instance;
final refApp = db.collection("tmp").doc();

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Console',
      theme: ThemeData(primarySwatch: Colors.brown),
      home: const MyHomePage(title: 'Console'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: refApp.snapshots(),
        builder: (context, snapshot) {
          final ag = snapshot.data?.data()?["ag"] as String? ?? "default";
          final refDev = db.collection("d").doc(ag);

          AppBar appBar(BuildContext context, String ag) => AppBar(
                title: Text("$ag - Detected devices"),
                actions: [
                  timeRateIndicator(refDev.collection("discovery")),
                  PopupMenuButton<String>(
                    initialValue: "",
                    onSelected: (String s) async {
                      if (s == "clear") {
                        for (var e
                            in (await refDev.collection("discovery").get())
                                .docs) {
                          e.reference.delete();
                        }
                      } else if (s == "vmstat") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => VmstatPage(refDev)),
                        );
                      } else if (s == "vmstatChart") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => VmstatChartPage(refDev)),
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        const PopupMenuItem(
                            value: "clear",
                            child: Text("Clear detected devices")),
                        const PopupMenuItem(
                            value: "vmstat", child: Text("Logs")),
                        const PopupMenuItem(
                            value: "vmstatChart", child: Text("Metrics")),
                      ];
                    },
                  ),
                ],
              );

          return Scaffold(
              appBar: appBar(context, ag),
//            floatingActionButton: FloatingActionButton(
//                child: const Icon(Icons.search), onPressed: () => {}),
              body: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(children: [
                  agentNameField(refApp),
                  discField(refDev),
                  Expanded(
                      child: discResultTable(refDev!
                          .collection("discovery")
                          .orderBy("time", descending: true)
                          .limit(100))),
                ]),
              ));
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
        var docApp = Application(snapshot.data?.data() ?? {});
        return TextField(
          controller: TextEditingController(text: docApp.ag ?? "default"),
          decoration: const InputDecoration(label: Text("Agent ID:")),
          onSubmitted: (ag) async {
            docApp.ag = ag;
            refApp.set(docApp.raw);
          },
        );
      });
}

Widget loadingIcon() => const Center(child: CircularProgressIndicator());
Widget noItem() => const Center(child: Text("No item"));

// Sample OID
const hrDeviceDescr = "1.3.6.1.2.1.25.3.2.1.3";
const hrDeviceStatus = "1.3.6.1.2.1.25.3.2.1.5";
const hrDeviceErrors = "1.3.6.1.2.1.25.3.2.1.6";
