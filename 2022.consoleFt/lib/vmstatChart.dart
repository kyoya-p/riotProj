import 'package:charts_flutter/flutter.dart';
import 'package:collection/collection.dart';
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

  VMLog(this.rawVmlog, this.vmTime, this.vs);
  static VMLog? from(dynamic rawVmlog, DateTime time, String log) {
    final v = splitter(log);
    if (v == null) return null;
    return VMLog(rawVmlog, time, splitter(log) as List<int>);
  }

  static VMLog? fromObj(dynamic e) =>
      VMLog.from(e, (e["time"] as Timestamp).toDate(), e["log"] as String);

  static Iterable<VMLog> fromObjs(dynamic v) => (v["logs"] as Iterable<dynamic>)
      .map((e) => VMLog.fromObj(e))
      .where((e) => e != null)
      .map((e) => e as VMLog);

  static Iterable<VMLog> fromDocs(Iterable<dynamic> v) =>
      v.expand((e) => VMLog.fromObjs(e.data()));

  final dynamic rawVmlog;
  final List<int> vs;
  final DateTime vmTime;
  int get procWaitRun => vs[0];
  int get procIoBlocked => vs[1];
  int get memSwap => vs[2];
  int get memFree => vs[3];
  int get memBuff => vs[4];
  int get memCache => vs[5];
  int get swapIn => vs[6];
  int get swapOut => vs[7];
  int get ioIn => vs[8];
  int get ioOut => vs[9];
  int get sysIntr => vs[10];
  int get sysCtxSw => vs[11];
  int get cpuUser => vs[12];
  int get cpuSys => vs[13];
  int get cpuIdle => vs[14];
  int get cpuWait => vs[15];
  int get cpuStolen => vs[16];
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
                //final vd = VMLog.fromDocs(ss.data!.docs);
                final vmlogs = VMLog.fromDocs(ss.data!.docs).sorted((a, b) =>
                    a.vmTime.millisecondsSinceEpoch -
                    b.vmTime.millisecondsSinceEpoch);
                return Column(children: [
                  Expanded(child: chart1(vmlogs)),
                  Expanded(child: chart2(vmlogs)),
                  Expanded(child: chart3(vmlogs)),
                  Expanded(child: chart4(vmlogs)),
                ]);
              }),
        ));
  }

  static chartSeries(
          List<VMLog> logs, String id, int Function(VMLog) getValue) =>
      charts.Series<VMLog, DateTime>(
        id: id,
        //colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (e, _) => e.vmTime,
        measureFn: (e, _) => getValue(e),
        data: logs,
      );
  static chartSeries2nd(
          List<VMLog> logs, String id, int Function(VMLog) getValue) =>
      chartSeries(logs, id, getValue)
        ..setAttribute(
          charts.measureAxisIdKey,
          charts.Axis.secondaryMeasureAxisId,
        );
  final layout = LayoutConfig(
    leftMarginSpec: MarginSpec.fromPixel(minPixel: 65),
    rightMarginSpec: MarginSpec.fromPixel(minPixel: 25),
    topMarginSpec: MarginSpec.fromPixel(minPixel: 0),
    bottomMarginSpec: MarginSpec.fromPixel(minPixel: 35),
  );
  final domainAxis = charts.DateTimeAxisSpec(
      tickFormatterSpec: BasicDateTimeTickFormatterSpec(
    (t) => '${t.hour}:${t.minute.toString().padLeft(2, "00")}',
  ));

  final List<ChartBehavior<DateTime>> commonBehaviors = [
    charts.SeriesLegend()
//    charts.SeriesLegend(position: BehaviorPosition.bottom)
  ];

  chartSnmp(List<VMLog> vmlogs) => charts.TimeSeriesChart(
        [
          chartSeries(vmlogs, "snmp scan", (v) => v.snmpCount),
        ],
        domainAxis: domainAxis,
        layoutConfig: layout,
        animate: false,
        behaviors: commonBehaviors,
        defaultRenderer: LineRendererConfig(includeArea: true, stacked: true),
      );

  chart1(List<VMLog> vmlogs) => charts.TimeSeriesChart(
        [
          chartSeries(vmlogs, "user", (v) => v.cpuUser),
          chartSeries(vmlogs, "sys", (v) => v.cpuSys),
          chartSeries(vmlogs, "stln", (v) => v.cpuStolen),
          chartSeries(vmlogs, "wait", (v) => v.cpuWait),
          chartSeries(vmlogs, "idle", (v) => v.cpuIdle),
        ],
        domainAxis: domainAxis,
        layoutConfig: layout,
        animate: false,
        behaviors: commonBehaviors,
        defaultRenderer: LineRendererConfig(includeArea: true, stacked: true),
      );
  chart2(List<VMLog> vmlogs) => charts.TimeSeriesChart(
        [
          chartSeries(vmlogs, "wait-run", (v) => v.procWaitRun),
          chartSeries(vmlogs, "io-blk", (v) => v.procIoBlocked),
        ],
        domainAxis: domainAxis,
        layoutConfig: layout,
        animate: false,
        behaviors: commonBehaviors,
      );
  chart3(List<VMLog> vmlogs) => charts.TimeSeriesChart(
        [
          chartSeries(vmlogs, "swap", (v) => v.memSwap),
          chartSeries(vmlogs, "buff", (v) => v.memBuff),
          chartSeries(vmlogs, "cache", (v) => v.memCache),
          chartSeries(vmlogs, "free", (v) => v.memFree),
        ],
        domainAxis: domainAxis,
        layoutConfig: layout,
        animate: false,
        behaviors: commonBehaviors,
        defaultRenderer: LineRendererConfig(includeArea: true, stacked: true),
      );
  chart4(List<VMLog> vmlogs) => charts.TimeSeriesChart(
        [
          chartSeries(vmlogs, "sw-in", (v) => v.swapIn),
          chartSeries(vmlogs, "sw-out", (v) => v.swapOut),
          chartSeries(vmlogs, "io-in", (v) => v.ioIn),
          chartSeries(vmlogs, "io-out", (v) => v.ioOut),
        ],
        domainAxis: domainAxis,
        layoutConfig: layout,
        animate: false,
        behaviors: commonBehaviors,
      );

  static List<charts.Series<dynamic, DateTime>> createData(List<VMLog> vmlogs) {
    return [
      //chartSeries("free", (v) => v.free),
      chartSeries(vmlogs, "User", (v) => v.cpuUser),
      chartSeries(vmlogs, "System", (v) => v.cpuSys),
      chartSeries(vmlogs, "Idle", (v) => v.cpuIdle),
      chartSeries(vmlogs, "Wait", (v) => v.cpuWait),
      chartSeries(vmlogs, "Stolen", (v) => v.cpuStolen),
    ];
  }
}

/// Sample linear data type.
class LinearVmstat {
  final Timestamp date;
  final int idle;

  LinearVmstat(this.date, this.idle);
}
