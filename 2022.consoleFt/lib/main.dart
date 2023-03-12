import 'dart:collection';
import 'dart:html';
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

// String defaultDevId = window.localStorage['deviceId'] ?? "default";

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeServerClock();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String devId = Uri.base.queryParameters["id"] ??
        window.localStorage["deviceId"] ??
        "default";
    refApp.set({"ag": devId});
    return MaterialApp(
      title: 'DevConsole',
      theme: ThemeData(primarySwatch: Colors.brown),
      home: MyHomePage(devId, title: 'DevConsole'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage(String this.devId, {Key? key, required this.title})
      : super(key: key);
  final String title;
  final String devId;

  PopupMenuItem<Function> menuDebugLog(
          BuildContext context, DocumentReference refDev) =>
      PopupMenuItem(
          value: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => DebugLogsPage(refDev)));
          },
          child: const Text("Debug Log"));
  PopupMenuItem<Function> menuDocEditor(
          BuildContext context, DocumentReference refDev) =>
      PopupMenuItem(
          value: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => DocumentPage(refDev)));
          },
          child: const Text("Document Editor"));
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
  PopupMenuItem<Function> menuInitForFSS(
          BuildContext context, DocumentReference refDev) =>
      PopupMenuItem(
          value: () => refDev.set({
                "fssSpec": {"initUrl": null, "adr": null}
              }),
          child: const Text("💀Initialize for FSS Device"));

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
              menuDocEditor(context, refDev),
              menuDebugLog(context, refDev),
              menuItem1(context, refDev),
              menuItem2(context, refDev),
              menuItem3(context, refDev),
              menuInitForFSS(context, refDev),
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
        final ag = snapshot.data?.data()?["ag"] as String? ?? devId;
        final refDev = refRoot.doc(ag);

        return Scaffold(
            appBar: appBar(context, ag, refDev),
//            floatingActionButton: FloatingActionButton(
//                child: const Icon(Icons.search), onPressed: () => {}),
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: [
                agentNameField(refApp),
                Expanded(child: consoleField(context, refDev)),
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
          controller: TextEditingController(text: docApp.ag),
          decoration: const InputDecoration(label: Text("Device ID:")),
          onSubmitted: (ag) async {
            docApp.ag = ag;
            window.localStorage["deviceId"] = ag;
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
        if (dev["ipSpec"] != null) return snmpScannerConsole(context, refDev);
        if (dev["fssSpec"] != null) return fssControlerField(context, refDev);
        return noItem();
      });
}

Widget snmpScannerConsole(BuildContext context, DocumentReference refDev) {
  final refSnmpDevList =
      refDev.collection("devices").orderBy("time", descending: true).limit(10);
  return Column(
    children: [
      discSettingField(refDev),
      SizedBox(height: 150, child: listMonitor(context, refSnmpDevList)),
      Expanded(child: RealtimeMericsWidget(refDev)),
    ],
  );
}
