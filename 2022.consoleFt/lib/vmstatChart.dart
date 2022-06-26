import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'main.dart';

Widget expanded(Widget w) => Expanded(child: w);

class VMLog {
  static List<int>? splitter(String log) {
    try {
      final v = log.trim().split(RegExp('\\s+'));
      if (v.length != 17) throw Exception();
      return v.map((e) => int.parse(e)).toList();
    } catch (e) {
      print('Exception:Log=$log');
      return null;
    }
  }

  VMLog(this.time, this.vs);
  static VMLog? from(DateTime time, String log) {
    final v = splitter(log);
    if (v == null) return null;
    return VMLog(time, splitter(log) as List<int>);
  }

  static VMLog? fromObj(dynamic e) =>
      VMLog.from((e["time"] as Timestamp).toDate(), e["log"] as String);

  static Iterable<VMLog> fromObjs(dynamic v) => (v["logs"] as Iterable<dynamic>)
      .map((e) => VMLog.fromObj(e))
      .where((e) => e != null)
      .map((e) => e as VMLog);

  final List<int> vs;
  final DateTime time;
  int get r => vs[0];
  int get free => vs[3];
  int get idle => vs[14];
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
                final vms = VMLog.fromObjs(ss.data!.docs);
                return charts.TimeSeriesChart(createData(vms.toList()),
                    animate: true);
              }),
        ));
  }

  static List<charts.Series<dynamic, DateTime>> createData(List<VMLog> vmlogs) {
    return [
      charts.Series<VMLog, DateTime>(
        id: 'free',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (e, _) => e.time,
        measureFn: (e, _) => e.free,
        data: vmlogs,
      ),
      charts.Series<VMLog, DateTime>(
        id: 'idle',
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
        domainFn: (e, _) => e.time,
        measureFn: (e, _) => e.idle,
        data: vmlogs,
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
