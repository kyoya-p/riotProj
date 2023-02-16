import 'dart:convert';
import 'package:flutter/material.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';

import 'documentPage.dart';

/*
Agent操作
*/
class RiotAgentMfpMibAppWidget extends StatelessWidget {
  final DocumentReference docRef;

  RiotAgentMfpMibAppWidget(this.docRef);

  final TextEditingController textController = TextEditingController();
  final TextEditingController name = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController cluster = TextEditingController();
  final TextEditingController config = TextEditingController();

  final _tabs = <Tab>[
    Tab(icon: Icon(Icons.settings), text: "Device"),
    Tab(icon: Icon(Icons.search), text: "Scan"),
    Tab(icon: Icon(Icons.access_time), text: "Schedule"),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: _tabs.length,
        child: StreamBuilder(
            stream: docRef.snapshots(),
            builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (!snapshot.hasData)
                return Center(child: CircularProgressIndicator());
              textController.text =
                  JsonEncoder.withIndent(" ").convert(snapshot.data!.data());
              return Scaffold(
                appBar: AppBar(
                    title: Text("${docRef.path} - Configuration"),
                    actions: [
                      IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => pushDocEditor(context, docRef))
                    ],
                    bottom: TabBar(tabs: _tabs)),
                body: TabBarView(children: <Widget>[
                  deviceSettings(context, snapshot),
                  scanSettingsTable(context, snapshot.data!),
                  Center(child: Text("Under Construction...")),
                ]),
                //body: form(context, snapshot),
                floatingActionButton: FloatingActionButton(
                  child: Icon(Icons.send),
                  onPressed: () {
                    var doc = json.decode(textController.text);
                    doc["time"] = DateTime.now().toUtc().millisecondsSinceEpoch;
                    docRef.set(doc);
                    Navigator.pop(context);
                  },
                ),
              );
            }));
  }

  Widget deviceSettings(
      BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
    DocumentSnapshot snapshotData = snapshot.data!;
    name.text = snapshotData.data()["name"];
    password.text = snapshotData.data()["password"];
    cluster.text = snapshotData.data()["cluster"];
    config.text =
        JsonEncoder.withIndent("  ").convert(snapshotData.data()["config"]);

    return Column(
      children: [
        TextField(
            controller: name,
            decoration:
                InputDecoration(labelText: "Name", icon: Icon(Icons.label))),
        TextField(
            controller: password,
            decoration: InputDecoration(
                labelText: "Password", icon: Icon(Icons.security))),
        TextField(
            controller: cluster,
            decoration: InputDecoration(
                labelText: "Cluster ID", icon: Icon(Icons.home_filled))),
        Padding(padding: EdgeInsets.all(5.0)),
        CheckboxListTile(
          title: Text("Automatic registration of detected devices"),
          value: true,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: null,
        ),
      ],
    );
  }

  Widget scanSettingsTable(BuildContext context, DocumentSnapshot snapshot) {
    List<dynamic> scans = snapshot.data()["config"]["scanAddrSpecs"];
    return DataTable(
      columns: ["IP", "Range", "Broadcast", ""]
          .map((e) => DataColumn(label: Text(e)))
          .toList(),
      rows: scans.map((e) => scanSettingsTableRow(e)).toList(),
    );
  }

  DataRow scanSettingsTableRow(dynamic scanAddr) {
    return DataRow(cells: [
      DataCell(TextField(
          controller:
              TextEditingController(text: scanAddr["addr"].toString()))),
      DataCell(TextField(
        controller: TextEditingController(text: scanAddr["addrRangeEnd"]),
        decoration: InputDecoration(
            hintText: "If empty, scan one address or broadcast"),
      )),
      DataCell(Checkbox(
        value: scanAddr["isBroadcast"] ?? false,
        onChanged: (value) {},
      )),
      DataCell(IconButton(
        icon: Icon(Icons.delete_rounded),
        onPressed: () {},
      ))
    ]);
  }

  static String type = "agent.mfp.mib";

  static Widget makeCellWidget(
      BuildContext context, QueryDocumentSnapshot devSnapshot) {
    return GestureDetector(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.blue[100],
        ),
        child: Column(
          children: [
            Row(children: [Icon(Icons.search), Text("${devSnapshot.id}")]),
            Row(
              children: [
                IconButton(
                    icon: Icon(Icons.play_circle_outline),
                    onPressed: () => update(devSnapshot)),
                IconButton(icon: Icon(Icons.list), onPressed: () => null)
              ],
            ),
          ],
        ),
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RiotAgentMfpMibAppWidget(devSnapshot.reference),
        ),
      ),
    );
  }

  static update(QueryDocumentSnapshot snapshot) {
    snapshot.reference.get().then((snapshot) {
      print(snapshot.data());
      dynamic data = snapshot.data();
      data["time"] = DateTime.now().toUtc().millisecondsSinceEpoch;
      snapshot.reference.set(data);
    });
  }
}

/*
SNMP Agent検索用コンソール
*/
class SnmpDiscoveryWidget extends StatelessWidget {
  final String groupId;

  SnmpDiscoveryWidget({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection("group")
          .doc(groupId)
          .collection("devices")
          .snapshots(),
      builder: (context, snapshot) => Row(
          children: [IconButton(icon: Icon(Icons.search), onPressed: null)]),
    );
  }
}
