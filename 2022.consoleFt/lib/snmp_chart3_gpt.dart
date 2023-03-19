import 'package:charts_flutter/flutter.dart';
import 'package:console_ft/types.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

// class SnmpLog {
//   final int reqCount; // リクエスト数
//   final int resCount; // レスポンス数
//   final DateTime time; // 時刻
//
//   SnmpLog(this.reqCount, this.resCount, this.time);
// }

class SnmpChart extends StatelessWidget {
  final List<SnmpLog> data; // オブジェクトの配列

  SnmpChart(this.data);

  @override
  Widget build(BuildContext context) {
    var series = [
      charts.Series<SnmpLog, DateTime>(
        id: '# SNMP Req',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (SnmpLog log, _) => log.time.toDate(),
        measureFn: (SnmpLog log, _) => log.reqCount,
        data: data,
      ),
      charts.Series<SnmpLog, DateTime>(
        id: '# SNMP Res',
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault.lighter,
        domainFn: (SnmpLog log, _) => log.time.toDate(),
        measureFn: (SnmpLog log, _) => log.resCount,
        data: data,
      ),
    ];

    SeriesRendererConfig<DateTime> renderer =
        charts.LineRendererConfig(includePoints: false);
    if (true) renderer = charts.BarRendererConfig<DateTime>();
    var chart = charts.TimeSeriesChart(
      series,
      animate: true,
      defaultRenderer: renderer,
      behaviors: [
        new charts.SeriesLegend(position: charts.BehaviorPosition.top)
      ],
      domainAxis: new charts.DateTimeAxisSpec(
          viewport: new charts.DateTimeExtents(
              start: new DateTime.now().subtract(new Duration(minutes: 30)),
              end: new DateTime.now()),
          showAxisLine: true),
      primaryMeasureAxis: new charts.NumericAxisSpec(showAxisLine: false),
      layoutConfig: new charts.LayoutConfig(
          leftMarginSpec: new charts.MarginSpec.fixedPixel(65),
          rightMarginSpec: new charts.MarginSpec.fixedPixel(25),
          topMarginSpec: new charts.MarginSpec.fixedPixel(0),
          bottomMarginSpec: new charts.MarginSpec.fixedPixel(35)),
    );

    // パディングを付けたコンテナウィジェットを作成
    var container = Container(
      //padding: EdgeInsets.all(10),
      child: chart,
    );

    return container;
  }
}

/*
CharGPT指示

flutterで下記オブジェクトの配列を横軸時系列で表示するコードを生成
{"reqCount":1,"resCount":10,"time":"12345"}
各ドキュメントはsnmpLogsを1つ持ち、snmpLogsは複数のカウンタ情報の配列
timeはfirestoreのDateTime型
クラス名はSnmpChart, StatelessWidgetを継承
オブジェクトの配列はコンストラクタのパラメタで与える
chart_flutterパッケージ使用

凡例をつける、位置はtop X軸には時間の目盛りを表示,X軸の範囲は現在の時刻から30分前まで,形式はHH:mm
layoutConfigのマージンの最小値は左65,右25,上0,下35
reqCountは青、resCountは薄い赤
グラフのタイトルや軸のラベルは不要
*/
