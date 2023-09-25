import 'package:charts_flutter/flutter.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class SnmpChart extends StatelessWidget {
  final Query query;
  final String chart;

  SnmpChart({required this.query, this.chart = "bar"});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        List<charts.Series<SnmpLog, DateTime>> seriesList =
            _createSeriesList(snapshot.data!.docs);
        SeriesRendererConfig<DateTime> renderer = charts.LineRendererConfig(includePoints: false);
        if (chart == "bar") renderer = charts.BarRendererConfig<DateTime>();
        return charts.TimeSeriesChart(
          seriesList,
          animate: true,
          defaultRenderer: renderer,
          layoutConfig: LayoutConfig(
            leftMarginSpec: MarginSpec.fromPixel(minPixel: 65),
            rightMarginSpec: MarginSpec.fromPixel(minPixel: 25),
            topMarginSpec: MarginSpec.fromPixel(minPixel: 0),
            bottomMarginSpec: MarginSpec.fromPixel(minPixel: 35),
          ),
          behaviors: [
            charts.SeriesLegend(position: charts.BehaviorPosition.top)
          ],
          domainAxis: charts.DateTimeAxisSpec(
            tickFormatterSpec: charts.AutoDateTimeTickFormatterSpec(
              day: charts.TimeFormatterSpec(
                  format: 'HH:mm', transitionFormat: 'HH:mm'),
            ),
            viewport: charts.DateTimeExtents(
                start: DateTime.now().subtract(Duration(hours: 2)),
                end: DateTime.now()),
          ),
        );
      },
    );
  }

  List<charts.Series<SnmpLog, DateTime>> _createSeriesList(
      List<QueryDocumentSnapshot> docs) {
    List<SnmpLog> data = docs
        .expand((doc) =>
            ((doc.data() as Map<String, dynamic>)['snmpLogs'] as List)
                .map((log) => SnmpLog.fromMap(log)))
        .toList();
    data.sort((a, b) => a.time.compareTo(b.time));
    return [
      charts.Series<SnmpLog, DateTime>(
          id: 'reqCount',
          colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault.lighter,
          domainFn: (SnmpLog log, _) => log.time,
          measureFn: (SnmpLog log, _) => log.reqCount,
          data: data),
      charts.Series<SnmpLog, DateTime>(
          id: 'resCount',
          colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault.lighter,
          domainFn: (SnmpLog log, _) => log.time,
          measureFn: (SnmpLog log, _) => log.resCount,
          data: data)
    ];
  }
}

class SnmpLog {
  final int reqCount;
  final int resCount;
  final DateTime time;

  SnmpLog({required this.reqCount, required this.resCount, required this.time});

  factory SnmpLog.fromMap(Map<String, dynamic> map) {
    return SnmpLog(
        reqCount: map['reqCount'],
        resCount: map['resCount'],
        time: (map['time'] as Timestamp).toDate());
  }
}

/*
GPT指示

flutterでfirestoreの下記ドキュメントのリストを横軸時系列で表示するコードを生成

{"snmpLogs":[{"reqCount":1,"resCount":10,"time":"12345"}] }
各ドキュメントはsnmpLogsを1つ持ち、snmpLogsは複数のカウンタ情報の配列
カウンタ情報はtimeの順にソートされグラフの右側が大きい
timeはfirestoreのDateTime型

クラス名はSnmpChart
StatelessWidgetを継承
StreamBuilderを使ってリアルタイムに更新
Queryをコンストラクタのパラメタqueryで与える
chart_flutterパッケージ使用
凡例をつける、位置はtop
X軸には時間の目盛りを表示,X軸の範囲は現在の時刻から2時間前まで
layoutConfigのマージンの最小値は上下左右各65,25,0,35
reqCountは青
resCountは薄い赤
棒グラフと折れ線グラフをメニューで選択できる
*/
