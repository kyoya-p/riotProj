import 'package:flutter/material.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_auth/firebase_auth.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:charts_flutter/flutter.dart' as charts;

// ignore: import_of_legacy_library_into_null_safe
import 'package:charts_common/common.dart' as common;
import 'package:riotagitator/ui/QueryBuilder.dart';

import 'documentPage.dart';

final FirebaseFirestore db = FirebaseFirestore.instance;
final User user = FirebaseAuth.instance.currentUser;

class Sample {
  final DateTime time;
  final int value;

  Sample(this.time, this.value);
}

class SynchroScopePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (user.uid == null) return Center(child: CircularProgressIndicator());

    Future<List<Sample>> sampler(Map<String, dynamic> synchroData) async {
      List<Sample> smpl = [];
      try {
        int now = DateTime.now().millisecondsSinceEpoch;

        Query? query = QueryBuilder(synchroData).build();
        if (query == null) return [];
        int resolution = synchroData["resolution"] ?? 3600;
        int end = synchroData["endTime"] ?? now;
        int samples = synchroData["samples"] ?? 3;
        int levelLimit = synchroData["levelLimit"] ?? 3;
        int left = end - samples * resolution;
        for (int i = samples; i > 0; --i) {
          smpl.add(Sample(
              DateTime.fromMillisecondsSinceEpoch(end - (i * resolution)), 0));
        }

        for (int start = left; start < end;) {
          //await Future.delayed(Duration(microseconds: 200)); //TODO 破産防止ディレイ
          Query query1 = db //TODO logのtimeの多単位を仮に1secとしている
              .collectionGroup("logs")
              .where("time", isGreaterThanOrEqualTo: start ~/ 1000)
              .where("time", isLessThan: end ~/ 1000)
              .limit(1);

          List<DocumentSnapshot> docs = (await query1.get()).docs;
          if (docs.length == 0) break;

          Map<String, dynamic> s = docs.first.data();
          int t = s["time"] as int;
          if (t < 1893456000) t = t * 1000;

          int level = (await db
                  .collectionGroup("logs")
                  .where("time", isGreaterThanOrEqualTo: t ~/ 1000)
                  .where("time", isLessThan: (t + resolution) ~/ 1000)
                  .limit(levelLimit)
                  .get())
              .docs
              .length;
          int idx = (t - left) ~/ resolution;
          smpl[idx] = Sample(DateTime.fromMillisecondsSinceEpoch(t), level);
          start = t + resolution;
        }
      } catch (ex) {
        print("Exception: $ex");
      }

      return smpl;
    }

    DocumentReference synchro = db.doc("user/${user.uid}/app1/synchro");
    Widget queryEditIcon(BuildContext context) => IconButton(
          icon: Icon(Icons.filter_list),
          onPressed: () => showDocumentEditorDialog(context, synchro),
        );

    return StreamBuilder<DocumentSnapshot>(
        stream: synchro.snapshots(),
        builder: (context, synchroSnapshot) {
          if (!synchroSnapshot.hasData)
            return Center(
              child: CircularProgressIndicator(),
            );
          Map<String, dynamic> synchroData = synchroSnapshot.data!.data();
          int right = synchroData["endTime"];
          int resolution = synchroData["resolution"]!;
          int samples = synchroData["samples"]!;
          int limit = synchroData["levelLimit"]!;
          int left = right - samples * resolution;

          return FutureBuilder(
            future: sampler(synchroSnapshot.data!.data()),
            builder:
                (BuildContext context, AsyncSnapshot<List<Sample>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  !snapshot.hasData)
                return Center(child: CircularProgressIndicator());
              return Scaffold(
                appBar: AppBar(
                  title: Text(
                      "${DateTime.fromMillisecondsSinceEpoch(left)} ~ ${DateTime.fromMillisecondsSinceEpoch(right)} / ${resolution ~/ 1000}[sec] LMT:$limit SPL:$samples"),
                  actions: [queryEditIcon(context)],
                ),
                body: customGesture(context,
                    child: synchroScopeWidget(snapshot.data!),
                    synchro: synchro),
              );
            },
          );
        });
  }

  Widget customGesture(BuildContext context,
      {required Widget? child, required DocumentReference synchro}) {
    shift(int percentOfRange) async {
      Map<String, dynamic> syncroData = (await synchro.get()).data();
      int endTime =
          syncroData["endTime"] ?? DateTime.now().millisecondsSinceEpoch;
      int samples = syncroData["samples"]!;
      int resolution = syncroData["resolution"]!;
      int shift = samples * resolution * percentOfRange ~/ 100;
      synchro.update({"endTime": endTime + shift});
    }

    zoom(int percent) async {
      Map<String, dynamic> syncroData = (await synchro.get()).data();
      int resolution = syncroData["resolution"]!;
      int newResolution = resolution * percent ~/ 100;
      if (newResolution < 1000) newResolution = 1000;
      synchro.update({"resolution": newResolution});
    }

    return GestureDetector(
      child: child,
      onLongPress: () async {
        await showDialog(
            context: context,
            builder: (BuildContext context) => SimpleDialog(
                  children: [
                    SimpleDialogOption(
                      child: Icon(Icons.zoom_in),
                      onPressed: () => zoom(50),
                    ),
                    Row(
                      children: [
                        SimpleDialogOption(
                          child: Icon(Icons.chevron_left),
                          onPressed: () => shift(-50),
                        ),
                        Spacer(),
                        SimpleDialogOption(
                          child: Icon(Icons.chevron_right),
                          onPressed: () => shift(50),
                        ),
                      ],
                    ),
                    SimpleDialogOption(
                      child: Icon(Icons.zoom_out),
                      onPressed: () => zoom(200),
                    ),
                  ],
                ));
      },
      onHorizontalDragEnd: (DragEndDetails details) async {
        if (details.velocity.pixelsPerSecond.dx.abs() > 500) {
          DocumentReference query = db.doc("user/${user.uid}/app1/synchro");
          Map<String, dynamic> syncroData = (await query.get()).data();
          int endTime =
              syncroData["endTime"] ?? DateTime.now().millisecondsSinceEpoch;
          int samples = syncroData["samples"]!;
          int resolution = syncroData["resolution"]!;
          endTime += (samples ~/ 2 * resolution) *
              -details.velocity.pixelsPerSecond.dx.compareTo(0);
          query.update({"endTime": endTime});
        }
      },
      onVerticalDragEnd: (DragEndDetails details) async {
        if (details.velocity.pixelsPerSecond.dy.abs() > 500) {
          DocumentReference query = db.doc("user/${user.uid}/app1/synchro");
          Map<String, dynamic> syncroData = (await query.get()).data();
          int resolution = syncroData["resolution"]!;
          if (details.velocity.pixelsPerSecond.dy >= 0) {
            query.update({"resolution": (resolution + 999) ~/ 2000 * 1000});
          } else {
            query.update({"resolution": resolution * 2});
          }
        }
      },
    );
  }
}

Widget synchroScopeWidget(List<Sample> samples) => charts.TimeSeriesChart(
      [
        common.Series<Sample, DateTime>(
          id: 'Level',
          colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
          domainFn: (Sample s, _) => s.time,
          measureFn: (Sample s, _) => s.value,
          data: samples,
        )
      ],
      animate: true,
      defaultRenderer: new charts.BarRendererConfig<DateTime>(),
      defaultInteractions: false,
      behaviors: [new charts.SelectNearest(), new charts.DomainHighlighter()],
    );
