import 'package:flutter/material.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';

import '../trial/ChartSample.dart';
import 'Common.dart';
import 'Demo.dart';
import 'Bell.dart';
import 'QueryViewPage.dart';
import 'documentPage.dart';

/* Cluster管理画面
   - 登録デバイス一覧表示
   - 新規デバイス登__GroupName__録
   - Cluster情報の編集
*/
class ClusterViewerPage extends StatelessWidget {
  ClusterViewerPage({required this.clusterId});

  final String clusterId;
  final db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return QueryViewPage(
      query: db.collection("device").where("cluster", isEqualTo: clusterId),
      itemBuilder: (context, index, devSnapshots) =>
          buildCellWidget(context, devSnapshots.data!.docs[index]),
      appBar: AppBar(
        title: Text("$clusterId - Cluster"),
        actions: [
          bell(context),
          clusterMenu(context),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () =>
                pushDocEditor(context, db.collection("group").doc(clusterId)),
          )
        ],
      ),
      floatingActionButton: defaultFloatingActionButton(context),
    );
  }

  Widget clusterMenu(BuildContext context) =>
      PopupMenuButton<Widget Function(BuildContext)>(
        itemBuilder: (BuildContext context) => [
          PopupMenuItem(
              child: Text("Add Generic Device Entry"),
              value: (_) =>
                  DocumentPage(db.collection("group").doc(clusterId))),
          PopupMenuItem(child: Text("Add SNMP Device Entry"), value: null),
          PopupMenuItem(
              child: Text("Add HTTP Device Entry"),
              value: (_) => DemoHumanHeatSensorCreatePage(clusterId)),
          PopupMenuItem(
              child: Text("😊体感温度センサーデバイス追加"),
              value: (_) => DemoHumanHeatSensorCreatePage(clusterId)),
          PopupMenuItem(
              child: Text("Log Viewer"), value: (_) => LogCountBarChartPage()),
        ],
        onSelected: (value) => naviPush(context, value),
      );

  Widget defaultFloatingActionButton(BuildContext context) =>
      FloatingActionButton(
        child: Icon(Icons.note_add_rounded),
        onPressed: () => naviPush(
          context,
          (_) => DocumentPage(db.collection("device").doc("__DeviceID__"))
            ..setDocWidget.textDocBody.text = """{
  "dev": {"cluster":"$clusterId"},
  "type":{"device":{}},
  "group":["$clusterId"]
}""",
        ),
      );
}
