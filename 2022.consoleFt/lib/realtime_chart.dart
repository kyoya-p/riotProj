import 'package:charts_flutter/flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

import 'main.dart';
import 'types.dart';

class RealtimeMericsWidget extends StatelessWidget {
  RealtimeMericsWidget(this.refDev, {Key? key}) : super(key: key);
  final DocumentReference refDev;
  @override
  Widget build(BuildContext context) {
    final refLogs = refDev
        .collection("reports")
        .orderBy("time", descending: true)
        .where("time",
            isGreaterThanOrEqualTo: Timestamp.fromMillisecondsSinceEpoch(
                DateTime.now().millisecondsSinceEpoch - 2 * 60 * 60 * 1000))
        .limit(120);
    return StreamBuilder<QuerySnapshot>(
        stream: refLogs.snapshots(),
        builder: (context, ssLogs) {
          if (ssLogs.hasError) return noItem();
          final docsLog = ssLogs.data?.docs.map((e) => Log(e));
          if (docsLog == null) return loadingIcon();
          final vmlogList = vVmlog(docsLog);
          return Column(children: [
            Expanded(child: chartVmstatCpu(vmlogList)),
            Expanded(child: chart2(vmlogList)),
            Expanded(child: chart3(vmlogList)),
            Expanded(child: chart4(vmlogList)),
          ]);
        });
  }

  List<VmLog> vVmlog(Iterable<Log> vlog) => vlog
      .expand((log) => log.vmlogs.toList().sorted((a, b) =>
          b.time.millisecondsSinceEpoch - a.time.millisecondsSinceEpoch))
      .toList();

  static chartSeries(
          List<VmLog> logs, String id, int Function(VmLog) getValue) =>
      charts.Series<VmLog, DateTime>(
        id: id,
        //colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (e, _) => e.time.toDate(),
        measureFn: (e, _) => getValue(e),
        data: logs,
      );
  final layout = LayoutConfig(
    leftMarginSpec: MarginSpec.fromPixel(minPixel: 65),
    rightMarginSpec: MarginSpec.fromPixel(minPixel: 25),
    topMarginSpec: MarginSpec.fromPixel(minPixel: 0),
    bottomMarginSpec: MarginSpec.fromPixel(minPixel: 35),
  );
  final domainAxis = charts.DateTimeAxisSpec(
      tickFormatterSpec: BasicDateTimeTickFormatterSpec(
    (t) => '${t.hour}:${t.minute.toString().padLeft(2, "0")}',
  ));

  final List<ChartBehavior<DateTime>> commonBehaviors = [
    charts.SeriesLegend()
//    charts.SeriesLegend(position: BehaviorPosition.bottom)
  ];

  chartVmstatCpu(List<VmLog> vmlogs) => charts.TimeSeriesChart(
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

  chart2(List<VmLog> vmlogs) => charts.TimeSeriesChart(
        [
          chartSeries(vmlogs, "wait-run", (v) => v.procWaitRun),
          chartSeries(vmlogs, "io-blk", (v) => v.procIoBlocked),
        ],
        domainAxis: domainAxis,
        layoutConfig: layout,
        animate: false,
        behaviors: commonBehaviors,
      );
  chart3(List<VmLog> vmlogs) => charts.TimeSeriesChart(
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
  chart4(List<VmLog> vmlogs) => charts.TimeSeriesChart(
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
}
