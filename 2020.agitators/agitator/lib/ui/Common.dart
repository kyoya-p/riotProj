import 'dart:async';

import 'package:flutter/material.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riotagitator/ui/AgentMfpMib.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riotagitator/ui/synchroScope.dart';

import 'Demo.dart';
import 'QuerySpecViewPage.dart';
import 'WebsocketTerminal.dart';
import 'collectionGroupPage.dart';
import 'documentPage.dart';

FirebaseFirestore db = FirebaseFirestore.instance;
User user = FirebaseAuth.instance.currentUser;

DecorationTween makeDecorationTween(Color c) => DecorationTween(
      begin: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(5.0),
      ),
      end: BoxDecoration(
        color: Colors.brown[100],
        borderRadius: BorderRadius.circular(5.0),
      ),
    );

Widget buildCellWidget(
    BuildContext context, QueryDocumentSnapshot devSnapshot) {
  Map<String, dynamic> data = devSnapshot.data();
  String type = data["dev.type"];
  if (type == RiotAgentMfpMibAppWidget.type) {
    return RiotAgentMfpMibAppWidget.makeCellWidget(context, devSnapshot);
  } else if (type == DemoHumanHeatSensorCreatePage.type) {
    return DemoHumanHeatSensorCreatePage.makeCellWidget(context, devSnapshot);
  } else {
    return buildGenericCard(context, devSnapshot.reference);
  }
}

Widget buildGenericCard(BuildContext context, DocumentReference dRef) {
  print("dRef=${dRef.path}"); //TODO
  return Card(
      color: Theme.of(context).cardColor,
      child: StreamBuilder<DocumentSnapshot>(
          stream: dRef.snapshots(),
          builder: (streamCtx, snapshot) {
            if (snapshot.hasError)
              return SelectableText("Snapshots Error: ${snapshot.toString()}");
            if (!snapshot.hasData)
              return Center(child: CircularProgressIndicator());
            String label = snapshot.data?.id ?? "noLabel";
            print("snapshot=${snapshot.data?.data()}"); //TODO
            return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.black26,
                ),
                child: GestureDetector(
                    child: Text(label, overflow: TextOverflow.ellipsis),
                    onTap: () => showDocumentEditorDialog(
                        streamCtx, snapshot.data!.reference)));
          }));
}

Widget wrapDocumentOperationMenu(DocumentSnapshot dRef, BuildContext context,
    {List<Widget> Function(BuildContext)? buttonBuilder, Widget? child}) {
  return GestureDetector(
    child: child,
    onTap: () => showDocumentEditorDialog(context, dRef.reference,
        buttonBuilder: buttonBuilder),
  );
}

naviPop<T extends Object?>(BuildContext context, [T? result]) =>
    Navigator.pop(context, result);

// some snippet
naviPush(BuildContext context, WidgetBuilder builder) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: builder,
    ),
  );
}

naviPushReplacement(BuildContext context, WidgetBuilder builder) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: builder,
    ),
  );
}

Future showAlertDialog(context, Widget content) async {
  await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
              title: Text('Alert Dialog'),
              content: content,
              actions: <Widget>[
                SimpleDialogOption(
                    child: Text('Close'),
                    onPressed: () => Navigator.pop(context)),
              ]));
}

Future<T?> showConfirmDialog<T>(
        context, String msg, T Function(BuildContext) op) =>
    showDialog<T>(
        context: context,
        builder: (BuildContext context) =>
            SimpleDialog(title: Text(msg), children: [
              SimpleDialogOption(
                  child: Text('OK'),
                  onPressed: () => Navigator.pop(context, op(context))),
              SimpleDialogOption(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.pop(context)),
            ]));

Widget fsStreamBuilder(Query ref, AsyncWidgetBuilder builder) =>
    StreamBuilder<QuerySnapshot>(
        stream: ref.snapshots(),
        builder: (context, snapshots) {
          if (!snapshots.hasData)
            return Center(child: CircularProgressIndicator());
          return builder(context, snapshots);
        });

Timer runPeriodicTimer(int start) =>
    Timer.periodic(Duration(milliseconds: 250), (timer) {
      int d = DateTime.now().toUtc().millisecondsSinceEpoch - start;
      if (d >= 5000) {
        timer.cancel();
      } else {
        //func()
      }
    });

// ignore: must_be_immutable
class MySwitchListTile extends StatefulWidget {
  MySwitchListTile({required this.title, this.value = false});

  final Widget title;
  bool value;

  @override
  State<StatefulWidget> createState() => _MySwitchTileState();
}

class _MySwitchTileState extends State<MySwitchListTile> {
  @override
  Widget build(BuildContext context) => SwitchListTile(
        onChanged: (sw) {
          setState(() => widget.value = sw);
        },
        value: widget.value,
        title: widget.title,
      );
}

// extension functions for debug
extension Debug on Object {
  pby(Function f) {
    print(f(this));
    return this;
  }

  p() {
    print(this);
    return this;
  }
}

extension MapExt on Map<String, dynamic>? {
  T? get<T>(String key) {
    if (this == null) return null;
    dynamic t = (this as Map<String, dynamic>)[key];
    if (t == null) return null;
    if (!(t is T)) return null;
    return t;
  }

  T? getNested<T>(List<String> keys) {
    Map<String, dynamic>? map = this;
    dynamic t;
    for (String key in keys) {
      if (map == null) return null;
      if (!map.containsKey(key)) return null;
      t = map[key];
      if (map[key] is Map<String, dynamic>?) map = map[key];
    }
    if (t == null) return null;
    if (!(t is T)) return null;
    return t;
  }
}

Widget globalGroupMenu(BuildContext context) {
  FirebaseFirestore db = FirebaseFirestore.instance;

  return PopupMenuButton<Widget Function(BuildContext)>(
    itemBuilder: (BuildContext context) => [
      PopupMenuItem(
          child: Text("Generic Query"),
          value: (_) => QuerySpecViewPage(
              queryDocument: db.doc("user/${user.uid}/app1/filterGeneral"))),
      PopupMenuItem(
          child: Text("User Viewer (admin)"),
          value: (_) => QuerySpecViewPage(
              queryDocument: db.doc("user/${user.uid}/app1/logFilter_user"))),
      PopupMenuItem(
          child: Text("Device Viewer (admin)"),
          value: (_) => QuerySpecViewPage(
              queryDocument: db.doc("user/${user.uid}/app1/logFilter_device"))),
      PopupMenuItem(
          child: Text("Group Viewer (admin)"),
          value: (_) => QuerySpecViewPage(
              //db.collection("group").where("users", arrayContains: user.uid),
              queryDocument: db.doc("user/${user.uid}/app1/logFilter_group"))),
      PopupMenuItem(
          child: Text("Notification Viewer (admin)"),
          value: (_) => CollectionGroupPage(db.collection("notification"))),
      PopupMenuItem(
          child: Text("Log Viewer (admin)"),
          value: (_) => CollectionGroupPage(db.collectionGroup("logs"),
              filterConfigRef: db.doc("user/${user.uid}/app1/logFilter"))),
      PopupMenuItem(
          child: Text("Log QueryView (admin)"),
          value: (_) => QuerySpecViewPage(
              queryDocument: db.doc("user/${user.uid}/app1/logFilter_logs"))),
      PopupMenuItem(
        child: Text("Series Histogram"),
        value: (_) {
          return SynchroScopePage();
        },
      ),
      PopupMenuItem(
        child: Text("  - Last 1 hour logs"),
        value: (_) => naviSynchroPage(12, 5 * 60, 3),
      ),
      PopupMenuItem(
        child: Text("  - Last 24 hours logs"),
        value: (_) => naviSynchroPage(12, 2 * 60 * 60, 10),
      ),
      PopupMenuItem(
        child: Text("  - Last 12 days logs"),
        value: (_) => naviSynchroPage(12, 12 * 24 * 60 * 60, 10),
      ),
      PopupMenuItem(
        child: Text("HTTP Terminal"),
        value: (_) {
          return WebsocketTerminalWidget();
        },
      ),
    ],
    onSelected: (value) => naviPush(context, value),
  );
}

Widget naviSynchroPage(int samples, int resolution, int levelLimit) {
  db.doc("user/${user.uid}/app1/synchro").set({
    "collectionGroup": "logs",
    "orderBy": [
      {"field": "time", "descending": false}
    ],
    "endTime": DateTime.now().millisecondsSinceEpoch ~/ 1000 * 1000,
    "samples": samples,
    "resolution": resolution * 1000,
    "levelLimit": levelLimit,
  });
  return SynchroScopePage();
}
