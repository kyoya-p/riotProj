import 'dart:async';
//import 'dart:html';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';

import 'Common.dart';
import 'Bell.dart';

class DemoHumanHeatSensorCreatePage extends StatelessWidget {
  DemoHumanHeatSensorCreatePage(this.clusterId);

  final db = FirebaseFirestore.instance;
  final String clusterId;
  static final String type = "human.feeling_temperature";

  @override
  Widget build(BuildContext context) {
    TextEditingController id = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: Text("体感温度センサーデバイス追加"),
        actions: [bell(context)],
      ),
      body: TextField(
        autofocus: true,
        controller: id,
        decoration: InputDecoration(
          labelText: "Device ID (お名前)",
          hintText: "本名でなくてもよいので自分にわかる文字列を入力してください。",
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.send),
        onPressed: () {
          Map<String, Object> devDoc = {
            "dev": {
              "cluster": clusterId,
              "type": type,
            },
            "password": "Sharp_#1",
          };
          db
              .collection("device")
              .doc(id.text)
              .set(devDoc)
              .then((_) => Navigator.pop(context))
              .catchError((e) =>
                  showAlertDialog(context, e.message + "\nrequest: $devDoc"));
        },
      ),
    );
  }

  static Widget makeCellWidget(
          BuildContext context, QueryDocumentSnapshot devSnapshot) =>
      DemoHumanHeatSensorCell(
        devSnapshot: devSnapshot,
      );
}

class DemoHumanHeatSensorCell extends StatefulWidget {
  DemoHumanHeatSensorCell({required this.devSnapshot});

  final QueryDocumentSnapshot devSnapshot;

  @override
  State<StatefulWidget> createState() =>
      DemoHumanHeatSensorCellStatus(devSnapshot);
}

class DemoHumanHeatSensorCellStatus extends State<DemoHumanHeatSensorCell>
    with SingleTickerProviderStateMixin {
  DemoHumanHeatSensorCellStatus(this.devSnapshot);

  final QueryDocumentSnapshot devSnapshot;
  Color bgColor = Colors.grey[200]!;
  late Timer timer;

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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  logging(QueryDocumentSnapshot devSnapshot, int value) {
    devSnapshot.reference.collection("logs").doc().set({
      "value": value,
      "time": DateTime.now().toUtc().millisecondsSinceEpoch
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget buildButton(String label, Color color, int value) => TextButton(
          //minWidth: 80,
          //height: 70,
          child: Text(label, style: TextStyle(color: color)),
          onPressed: () => logging(widget.devSnapshot, value),
        );
    return StreamBuilder(
        stream: devSnapshot.reference
            .collection("logs")
            .orderBy("time", descending: true)
            .limit(1)
            .snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshots) {
          if (!snapshots.hasData)
            return Center(child: CircularProgressIndicator());
          QuerySnapshot logsSnapshotData = snapshots.data!;

          AnimationController controllerAA = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 5000),
          )..forward();

          Color c = Colors.black26;
          if (logsSnapshotData.size != 0) {
            Map<String, dynamic> log = logsSnapshotData.docs[0].data();
            int t = DateTime.now().toUtc().millisecondsSinceEpoch -
                log["time"] as int;
            Color c = log["value"] > 0
                ? Color.fromRGBO(255, 0, 0, 1)
                : Color.fromRGBO(0, 0, 255, 1);
            controllerAA.value = t / 10000;
            makeDecorationTween(c).animate(controllerAA..forward());
          }

          return GestureDetector(
            child: DecoratedBoxTransition(
                decoration:
                    makeDecorationTween(c).animate(controllerAA..forward()),
                child: Column(children: [
                  Row(children: [
                    Text("${devSnapshot.id}"),
                  ]),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        buildButton("Hot", Colors.red, 1),
                        buildButton("Cold", Colors.blue, -1),
                      ])
                ])),
            onLongPress: () =>
                naviPush(context, (_) => DeviceLogPage(devSnapshot)),
          );
        });
  }

//@override
//void debugFillProperties(DiagnosticPropertiesBuilder properties) {
//  super.debugFillProperties(properties);
//  properties.add(
//      DiagnosticsProperty<AnimationController>('_controller', _controllerAA));
//}
}

class DeviceLogPage extends StatelessWidget {
  final QueryDocumentSnapshot devSnapshot;

  DeviceLogPage(this.devSnapshot);

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(),
      body: StreamBuilder<QuerySnapshot>(
          stream: devSnapshot.reference
              .collection("logs")
              .orderBy("time", descending: true)
              .limit(30)
              .snapshots(),
          builder: (context, snapshots) {
            if (!snapshots.hasData)
              return Center(child: CircularProgressIndicator());
            QuerySnapshot logsSnapshotsData = snapshots.data!;
            return Table(
              children: logsSnapshotsData.docs
                  .map((e) => TableRow(children: [
                        TableCell(
                            child: Text(DateTime.fromMillisecondsSinceEpoch(
                                    e.data()["time"],
                                    isUtc: false)
                                .toString())),
                        TableCell(
                          child: Text((e.data()["value"] > 0) ? "Hot" : "Cold"),
                        )
                      ]))
                  .toList(),
            );
          }));
}
