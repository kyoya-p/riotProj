import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'clock.dart';
import 'firebase_options.dart';
import 'realtime_chart.dart';
import 'snmp.dart';
import 'types.dart';
import 'log_viewer.dart';

final db = FirebaseFirestore.instance;
final refApp = db.collection("tmp").doc();

const defaultDevId = "default";
//const defaultDevId = "sc";

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeServerClock();
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

  PopupMenuItem<Function> menuItem1(
          BuildContext context, DocumentReference refDev) =>
      PopupMenuItem(
          value: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => DetectedDevicesPage(refDev)));
          },
          child: const Text("Detected Devices"));
  PopupMenuItem<Function> menuItem2(
          BuildContext context, DocumentReference refDev) =>
      PopupMenuItem(
          value: () async {
            for (final e in (await refDev.collection("discovery").get()).docs) {
              e.reference.delete();
            }
          }, // "clear",
          child: const Text("Clear detected devices"));
  PopupMenuItem<Function> menuItem3(
          BuildContext context, DocumentReference refDev) =>
      PopupMenuItem(
          value: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => LogsPage(refDev)));
          },
          child: const Text("Vmstat Logs"));

  AppBar appBar(BuildContext context, String ag, DocumentReference refDev) {
    print(refDev.path);
    return AppBar(
      title: Text("$ag - Monitor [${refDev.path}]"),
      actions: [
        aliveIndicator(refDev),
        PopupMenuButton<Function>(
          initialValue: () {},
          onSelected: (Function f) => f(),
          itemBuilder: (BuildContext context) {
            return [
              menuItem1(context, refDev),
              menuItem2(context, refDev),
              menuItem3(context, refDev),
            ];
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: refApp.snapshots(),
      builder: (context, snapshot) {
        final ag = snapshot.data?.data()?["ag"] as String? ?? defaultDevId;
        final refDev = db.collection("d").doc(ag);
        print('L1:${refDev.path}');
        return Scaffold(
            appBar: appBar(context, ag, refDev),
//            floatingActionButton: FloatingActionButton(
//                child: const Icon(Icons.search), onPressed: () => {}),
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: [
                agentNameField(refApp),
                discSettingField(refDev),
                Expanded(child: RealtimeMericsWidget(refDev)),
                //Expanded(child: DetectedDevicesWidget(refDev)),
              ]),
            ));
      },
    );
  }
}

Widget aliveIndicator(DocumentReference refDev) {
  const nLog = 1;
  final now = getServerTime();
  final qrLog = refDev
      .collection("reports")
      .where("time", isGreaterThan: now.subtract(const Duration(minutes: 1)))
      .limit(nLog);

  Widget alive() => const Center(child: Icon(Icons.favorite));
  Widget noSignal() =>
      const Center(child: Icon(Icons.heart_broken, color: Colors.red));
  return StreamBuilder<QuerySnapshot>(
      stream: qrLog.snapshots(),
      builder: (_, snapshots) {
        final docsLog = snapshots.data?.docs;
        if (docsLog == null) return loadingIcon();
        if (docsLog.length < nLog) return noSignal();
        return alive();
      });
}

Widget agentNameField(DocumentReference<Map<String, dynamic>> refApp) {
  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: refApp.snapshots(),
      builder: (context, snapshot) {
        var docApp = Application(snapshot.data?.data() ?? {});
        return TextField(
          controller: TextEditingController(text: docApp.ag ?? defaultDevId),
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

// Widget intervalBuilder<T>(Duration interval,
//     {required Widget Function(BuildContext, AsyncSnapshot<dynamic>) builder}) {
//   Stream<dynamic>? stream() async* {
//     while (true) {
//       yield null;
//       sleep(interval);
//     }
//   }

//   return StreamBuilder<T>(
//     stream: stream(),
//     builder: (context, snapshot) {
//       return builder(context, snapshot);
//     },
//   );
// }

// Sample OID
const hrDeviceDescr = "1.3.6.1.2.1.25.3.2.1.3";
const hrDeviceStatus = "1.3.6.1.2.1.25.3.2.1.5";
const hrDeviceErrors = "1.3.6.1.2.1.25.3.2.1.6";
