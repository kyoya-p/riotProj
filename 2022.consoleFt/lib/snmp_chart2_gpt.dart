import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class SnmpChart extends StatelessWidget {
  final Query query;

  SnmpChart({required this.query});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        List<charts.Series<SnmpLog, DateTime>> seriesList = [
          charts.Series<SnmpLog, DateTime>(
            id: 'reqCount',
            domainFn: (SnmpLog log, _) => log.time,
            measureFn: (SnmpLog log, _) => log.reqCount,
            data: snapshot.data!.docs
                .expand((doc) => doc['snmpLogs'])
                .map((log) => SnmpLog.fromMap(log))
                .toList()..sort((a, b) => a.time.compareTo(b.time)),
          ),
          charts.Series<SnmpLog, DateTime>(
            id: 'resCount',
            domainFn: (SnmpLog log, _) => log.time,
            measureFn: (SnmpLog log, _) => log.resCount,
            data: snapshot.data!.docs
                .expand((doc) => doc['snmpLogs'])
                .map((log) => SnmpLog.fromMap(log))
                .toList()..sort((a, b) => a.time.compareTo(b.time)),
          ),
        ];

        return charts.TimeSeriesChart(
          seriesList,
          animate: true,
          defaultRenderer: charts.BarRendererConfig<DateTime>(),
          behaviors: [charts.SeriesLegend()],
          domainAxis: charts.DateTimeAxisSpec(
              viewport: charts.DateTimeExtents(
                  start: DateTime.now().subtract(Duration(hours: 2)),
                  end: DateTime.now())),
        );
      },
    );
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
      time: (map['time'] as Timestamp).toDate(),
    );
  }
}

/*
GPT指示

flutterでfirestoreの下記ドキュメントのリストを横軸時系列で棒グラフを表示するコードを生成

{"snmpLogs":[{"reqCount":1,"resCount":10,"time":"12345"}] }
各オブジェクトはsnmpLogsを持つ
snmpLogsはカウンタ情報の配列
カウンタ情報はtimeの順にソートしグラフの右側が大きい
timeはfirestoreのDateTime型

クラス名はSnmpChart
StatelessWidgetを継承
StreamBuilderを使ってリアルタイムに更新
Queryをコンストラクタのパラメタqueryで与える
chart_flutterパッケージ使用
グラフの上の方に凡例をつける
X軸には時間の目盛りを表示,X軸の範囲は現在の時刻から2時間前まで
reqCountは青
resCountは薄い青
*/
