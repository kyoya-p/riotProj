import 'package:charts_flutter/flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:console_ft/snmp_chart4_gpt.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

import 'snmp_chart3_gpt.dart';
import 'main.dart';
import 'types.dart';

class RealtimeMetricsWidget extends StatelessWidget {
  const RealtimeMetricsWidget(this.refDev, {Key? key}) : super(key: key);
  final DocumentReference refDev;

  @override
  Widget build(BuildContext context) {
    const dataRange = 2 * 60 * 60 * 1000; //ms
    var refLogs = refDev
        .collection("reports")
        .orderBy("time", descending: true)
        .where("time",
            isGreaterThanOrEqualTo: Timestamp.fromMillisecondsSinceEpoch(
                DateTime.now().millisecondsSinceEpoch - dataRange))
        .limit(120);

    return StreamBuilder<QuerySnapshot>(
        stream: refLogs.snapshots(),
        builder: (context, ssLogs) {
          if(!ssLogs.hasData) return loadingIcon();
          final DateTime end = DateTime.now();
          final DateTime start = DateTime.fromMillisecondsSinceEpoch(
              end.millisecondsSinceEpoch - dataRange);
          refLogs = refLogs.where("time", isGreaterThanOrEqualTo: start);
          final domainAxis = charts.DateTimeAxisSpec(
              viewport: DateTimeExtents(start: start, end: end),
              tickFormatterSpec: BasicDateTimeTickFormatterSpec(
                (t) => '${t.hour}:${t.minute.toString().padLeft(2, "0")}',
              ));

          chartSeriesDebug(Iterable<DebugLog> logs, String id,
                  int Function(DebugLog) getValue) =>
              charts.Series<DebugLog, DateTime>(
                id: id,
                colorFn: (e, i) => MaterialPalette.blue.shadeDefault,
                domainFn: (e, _) => e.time.toDate(),
                measureFn: (e, _) => getValue(e),
                data: logs.toList(),
              );

          final layout = LayoutConfig(
            leftMarginSpec: MarginSpec.fromPixel(minPixel: 65),
            rightMarginSpec: MarginSpec.fromPixel(minPixel: 25),
            topMarginSpec: MarginSpec.fromPixel(minPixel: 0),
            bottomMarginSpec: MarginSpec.fromPixel(minPixel: 35),
          );

          final List<ChartBehavior<DateTime>> commonBehaviors = [
            charts.SeriesLegend(position: BehaviorPosition.top)
            // charts.SeriesLegend(position: BehaviorPosition.inside)
            //charts.SeriesLegend(position: BehaviorPosition.bottom)
          ];

          if (ssLogs.hasError) return noItem();
          final vLog = ssLogs.data?.docs.map((e) => Log(e));
          if (vLog == null) return loadingIcon();

          Iterable<DebugLog> allLogs = vLog.expand((e) => e.debugLogs
              .toList()
              .sorted((a, b) =>
                  b.time.millisecondsSinceEpoch -
                  a.time.millisecondsSinceEpoch));
          Iterable<DebugLog> logs(String kind) =>
              allLogs.where((e) => e.kind == kind);
          Iterable<DebugLog> initLogs = logs("INITIAL");
          Iterable<DebugLog> poll1Logs = logs("RMM:POLLING1");
          Iterable<DebugLog> poll2lLgs = logs("RMM:POLLING2");
          Iterable<DebugLog> mibReqLogs = logs("RMM:MIB_INFO_REQUEST");
          Iterable<DebugLog> mibResLogs = logs("RMM:MIB_INFO_RESULT");
//           chartFSS() => charts.TimeSeriesChart([
//                 // chartSeriesDebug(allLogs, "All logs", (v) => 0.2),
//                 chartSeriesDebug(initLogs, "Initialize", (v) => 10),
//                 chartSeriesDebug(poll1Logs, "Polling1", (v) => 5),
//                 chartSeriesDebug(poll2lLgs, "Polling2", (v) => 10),
//                 chartSeriesDebug(mibReqLogs, "MIB request", (v) => 10),
//                 chartSeriesDebug(mibResLogs, "MIB result", (v) => 10),
//               ],
//                   domainAxis: domainAxis,
//                   layoutConfig: layout,
//                   animate: false,
//                   behaviors: commonBehaviors,
//                   primaryMeasureAxis: charts.NumericAxisSpec(
//                       renderSpec: charts.NoneRenderSpec()),
//                   defaultRenderer: BarRendererConfig(maxBarWidthPx: 1));
// //                      LineRendererConfig(includeArea: true, stacked: true));

          List<DebugLog> debugLogs = vLog
              .expand((e) => e.debugLogs.toList().sorted((a, b) =>
                  b.time.millisecondsSinceEpoch -
                  a.time.millisecondsSinceEpoch))
              .toList();
          List<SnmpLog> snmpLogs = vLog
              .expand((e) => e.snmpLogs.toList().sorted((a, b) =>
                  b.time.millisecondsSinceEpoch -
                  a.time.millisecondsSinceEpoch))
              .toList();

          return Column(children: [
            SizedBox.fromSize(
                size: Size.fromHeight(100), child: DebugLogChart(debugLogs)),
            Expanded(child: SnmpChart(snmpLogs)),
          ]);
        });
  }
}
