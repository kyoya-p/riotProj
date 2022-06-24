import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'main.dart';

Widget expanded(Widget w) => Expanded(child: w);

class VmstatLog {
  static splitter(String log) {
    final v = log.trim().split(RegExp('\\s+'));
    if (v.length != 17) throw Exception();
    return v.map((e) => int.parse(e)).toList();
  }

  VmstatLog(this.time, this.ns);
  static VmstatLog? fromString(DateTime time, String log) {
    try {
      return VmstatLog(time, splitter(log));
    } catch (e) {
      return null;
    }
  }

  final List<int> ns;
  final DateTime time;
  int get r => ns[0];
  int get free => ns[3];
  int get idle => ns[14];
}

class VmstatChartPage extends StatelessWidget {
  //final List<charts.Series<dynamic, num>> seriesList;
  //final bool? animate;

  //VmstatChartPage(this.seriesList, {this.animate});
  VmstatChartPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (refDev == null) return loadingIcon();
    final refVmstat = refDev!
        .collection("vmstat")
        .orderBy("time", descending: true)
        .limit(24);
    return Scaffold(
        appBar: AppBar(title: Text('${refDev!.id} - vmstat')),
        body: Center(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: refVmstat.snapshots(),
              builder: (context, ss) {
                if (!ss.hasData || ss.data!.docs.isEmpty) return loadingIcon();
                final logs = ss.data!.docs
                    .expand((e) => (e.data()["logs"] as List<dynamic>).reversed)
                    .toList();

                return charts.TimeSeriesChart(createData(logs), animate: true);
              }),
        ));
  }

  static List<charts.Series<dynamic, DateTime>> createData(List<dynamic> logs) {
    final vmlogs = logs.map((e) => VmstatLog.fromString(e)).toList();

    logSplitter(String log) => log
        .split(RegExp('\\s+'))
        .where((e) => e.isNotEmpty)
        .map(
          (e) => int.parse(e),
        )
        .toList();
    return [
      charts.Series<dynamic, DateTime>(
        id: 'free',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (e, _) => (e["time"] as Timestamp).toDate(),
        measureFn: (e, _) => logSplitter(e["log"] as String)[3],
        data: logs,
      ),
      charts.Series<dynamic, DateTime>(
        id: 'idle',
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
        domainFn: (e, _) => (e["time"] as Timestamp).toDate(),
        measureFn: (e, _) => logSplitter(e["log"] as String)[14],
        data: logs,
      )..setAttribute(
          charts.measureAxisIdKey,
          charts.Axis.secondaryMeasureAxisId,
        ),
    ];
  }
}

/// Sample linear data type.
class LinearVmstat {
  final Timestamp date;
  final int idle;

  LinearVmstat(this.date, this.idle);
}
