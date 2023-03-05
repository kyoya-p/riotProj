import 'dart:async';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'clock.dart';
import 'debuglog_viewer.dart';
import 'document_editor.dart';
import 'firebase_options.dart';
import 'fss_controller.dart';
import 'realtime_chart.dart';
import 'snmp.dart';
import 'types.dart';
import 'vmlog_viewer.dart';

final db = FirebaseFirestore.instance;
final refRoot = db.collection("d");
final refTmp = refRoot.doc("0-tmp");
final refApp = refTmp.collection("app").doc();

const defaultDevId = "default";

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
      title: 'Dummy Device Dashboard',
      theme: ThemeData(primarySwatch: Colors.blueGrey),
      home: const MyHomePage(title: 'Dummy Device Dashboard'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  PopupMenuItem<Function> menuDebugLog(
          BuildContext context, DocumentReference refDev) =>
      PopupMenuItem(
          value: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => DebugLogsPage(refDev)));
          },
          child: const Text("Debug Log"));
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
            for (final e in (await refDev.collection("devices").get()).docs) {
              e.reference.delete();
            }
          },
          child: const Text("Clear detected devices"));
  PopupMenuItem<Function> menuItem3(
          BuildContext context, DocumentReference refDev) =>
      PopupMenuItem(
          value: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => LogsPage(refDev)));
          },
          child: const Text("Vmstat Logs"));
  PopupMenuItem<Function> menuItem4(
          BuildContext context, DocumentReference refDev) =>
      PopupMenuItem(
          value: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => DocumentPage(refDev)));
          },
          child: const Text("Document Editor"));

  AppBar appBar(BuildContext context, String ag, DocumentReference refDev) {
    return AppBar(
      title: Text("$ag - $title"),
      actions: [
        aliveIndicator(context, refDev),
        PopupMenuButton<Function>(
          initialValue: () {},
          onSelected: (Function f) => f(),
          itemBuilder: (BuildContext context) {
            return [
              menuDebugLog(context, refDev),
              menuItem1(context, refDev),
              menuItem2(context, refDev),
              menuItem3(context, refDev),
              menuItem4(context, refDev),
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
        final refDev = refRoot.doc(ag);

        return Scaffold(
            appBar: appBar(context, ag, refDev),
//            floatingActionButton: FloatingActionButton(
//                child: const Icon(Icons.search), onPressed: () => {}),
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: [
                agentNameField(refApp),
                consoleField(context, refDev),
                Expanded(child: RealtimeMericsWidget(refDev)),
                //Expanded(child: DetectedDevicesWidget(refDev)),
              ]),
            ));
      },
    );
  }
}

Widget aliveIndicator(BuildContext context, DocumentReference refDev) {
  const nLog = 1;
  final now = getServerTime();
  final qrLog = refDev
      .collection("reports")
      .where("time", isGreaterThan: now.subtract(const Duration(minutes: 1)))
      .limit(nLog);

  Widget alive(Log log) => Center(
        child: IconButton(
          icon: const Icon(Icons.favorite),
          onPressed: () => showDialog(
              context: context,
              builder: (context) => SimpleDialog(
                    children: [
                      Text(' Last communication: ${log.time.toDate()} ')
                    ],
                  )),
        ),
      );
  Widget noSignal() =>
      const Center(child: Icon(Icons.heart_broken, color: Colors.red));
  return StreamBuilder<QuerySnapshot>(
      stream: qrLog.snapshots(),
      builder: (_, snapshots) {
        final docsLog = snapshots.data?.docs;
        if (docsLog == null) return loadingIcon();
        if (docsLog.length < nLog) return noSignal();
        return alive(Log(docsLog[0].data()));
      });
}

Widget agentNameField(DocumentReference<Map<String, dynamic>> refApp) {
  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: refApp.snapshots(),
      builder: (context, snapshot) {
        var docApp = Application(snapshot.data?.data() ?? {});
        return TextField(
          controller: TextEditingController(text: docApp.ag ?? defaultDevId),
          decoration: const InputDecoration(label: Text("Device ID:")),
          onSubmitted: (ag) async {
            docApp.ag = ag;
            refApp.set(docApp.raw);
          },
        );
      });
}

Widget loadingIcon() => const Center(child: CircularProgressIndicator());
Widget noItem() => const Center(child: Text("No item"));

Widget consoleField(BuildContext context, DocumentReference refDev) {
  return StreamBuilder<DocumentSnapshot>(
      stream: refDev.snapshots(),
      builder: (context, snapshots) {
        final dev = snapshots.data?.data() as Map<String, dynamic>?;
        if (dev == null) return noItem();

        final refSnmpDevList = refDev
            .collection("devices")
            .orderBy("time", descending: true)
            .limit(10);
        final Widget listDevs =
            SizedBox(height: 150, child: listMonitor(context, refSnmpDevList));

        return Column(
          // mainAxisSize: MainAxisSize.min,
          children: [
            if (dev["ipSpec"] != null) discSettingField(refDev),
            if (dev["ipSpec"] != null) listDevs,
            if (dev["fssSpec"] != null) fssControlerField(context, refDev),
          ],
        );
      });
}
