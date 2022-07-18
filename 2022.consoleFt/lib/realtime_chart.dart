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
          final vLog = ssLogs.data?.docs.map((e) => Log(e));
          if (vLog == null) return loadingIcon();
          final vmlogList = vVmlog(vLog);
          final snmpLogList = vSnmplog(vLog);
          return Column(children: [
            Expanded(child: chartSnmp(snmpLogList)),
            Expanded(child: chartVmstatCpu(vmlogList)),
            Expanded(child: chartQueue(vmlogList)),
            Expanded(child: chartMemory(vmlogList)),
            Expanded(child: chartSwapIo(vmlogList)),
          ]);
        });
  }

  List<VmLog> vVmlog(Iterable<Log> vlog) => vlog
      .expand((log) => log.vmlogs.toList().sorted((a, b) =>
          b.time.millisecondsSinceEpoch - a.time.millisecondsSinceEpoch))
      .toList();
  List<SnmpLog> vSnmplog(Iterable<Log> vlog) => vlog
      .expand((log) => log.snmpLogs.toList().sorted((a, b) =>
          b.time.millisecondsSinceEpoch - a.time.millisecondsSinceEpoch))
      .toList();

  static chartSeriesVmstat(
          List<VmLog> logs, String id, int Function(VmLog) getValue) =>
      charts.Series<VmLog, DateTime>(
        id: id,
        //colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (e, _) => e.time.toDate(),
        measureFn: (e, _) => getValue(e),
        data: logs,
      );
  static chartSeriesSnmp(
          List<SnmpLog> logs, String id, int Function(SnmpLog) getValue) =>
      charts.Series<SnmpLog, DateTime>(
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
          chartSeriesVmstat(vmlogs, "user", (v) => v.cpuUser),
          chartSeriesVmstat(vmlogs, "sys", (v) => v.cpuSys),
          chartSeriesVmstat(vmlogs, "stln", (v) => v.cpuStolen),
          chartSeriesVmstat(vmlogs, "wait", (v) => v.cpuWait),
          chartSeriesVmstat(vmlogs, "idle", (v) => v.cpuIdle),
        ],
        domainAxis: domainAxis,
        layoutConfig: layout,
        animate: false,
        behaviors: commonBehaviors,
        defaultRenderer: LineRendererConfig(includeArea: true, stacked: true),
      );

  chartQueue(List<VmLog> vmlogs) => charts.TimeSeriesChart(
        [
          chartSeriesVmstat(vmlogs, "proc", (v) => v.procWaitRun),
          chartSeriesVmstat(vmlogs, "io", (v) => v.procIoBlocked),
        ],
        domainAxis: domainAxis,
        layoutConfig: layout,
        animate: false,
        behaviors: commonBehaviors,
      );
  chartMemory(List<VmLog> vmlogs) => charts.TimeSeriesChart(
        [
          chartSeriesVmstat(vmlogs, "swap", (v) => v.memSwap),
          chartSeriesVmstat(vmlogs, "buff", (v) => v.memBuff),
          chartSeriesVmstat(vmlogs, "cache", (v) => v.memCache),
          chartSeriesVmstat(vmlogs, "free", (v) => v.memFree),
        ],
        domainAxis: domainAxis,
        layoutConfig: layout,
        animate: false,
        behaviors: commonBehaviors,
        defaultRenderer: LineRendererConfig(includeArea: true, stacked: true),
      );
  chartSwapIo(List<VmLog> vmlogs) => charts.TimeSeriesChart(
        [
          chartSeriesVmstat(vmlogs, "sw-in", (v) => v.swapIn),
          chartSeriesVmstat(vmlogs, "sw-out", (v) => v.swapOut),
          chartSeriesVmstat(vmlogs, "io-in", (v) => v.ioIn),
          chartSeriesVmstat(vmlogs, "io-out", (v) => v.ioOut),
        ],
        domainAxis: domainAxis,
        layoutConfig: layout,
        animate: false,
        behaviors: commonBehaviors,
      );
  chartSnmp(List<SnmpLog> snmpLogs) => charts.TimeSeriesChart(
        [
          //chartSeriesSnmp(snmpLogs, "total req", (v) => v.snmpScanCount),
          charts.Series<SnmpLog, DateTime>(
            id: "req /s",
            domainFn: (e, _) => e.time.toDate(),
            measureFn: (_, i) {
              if (i == snmpLogs.length - 1) {
                return null;
              }
              return (snmpLogs[i as int].snmpScanCount -
                      snmpLogs[(i) + 1].snmpScanCount) /
                  60;
            },
            data: snmpLogs,
          ),
        ],
        domainAxis: domainAxis,
        layoutConfig: layout,
        animate: false,
        behaviors: commonBehaviors,
      );
}
