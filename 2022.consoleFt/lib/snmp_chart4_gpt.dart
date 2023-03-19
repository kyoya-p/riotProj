import 'dart:math';
import 'package:console_ft/types.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class DebugLogChart extends StatelessWidget {
  final List<DebugLog> data;
  final Map<String, int> kinds = {
    "INITIAL": 10,
    "RMM:POLLING1": 1,
    "RMM:POLLING2": 5,
    "RMM:MIB_INFO_REQUEST": 10,
    "RMM:MIB_INFO_RESULT": 10
  };

  DebugLogChart(this.data);

  @override
  Widget build(BuildContext context) {
// シリーズデータのリスト
    List<charts.Series<DebugLog, DateTime>> seriesList = [];

// kindごとにグループ化したマップ
    Map<String, List<DebugLog>> groupedMap = {};

// オブジェクトの配列からkindごとにグループ化する
    for (var log in data) {
      if (groupedMap.containsKey(log.kind)) {
        groupedMap[log.kind]!.add(log);
      } else {
        groupedMap[log.kind] = [log];
      }
    }

// kindごとにシリーズデータを作成する
    for (var kind in kinds.keys) {
      if (groupedMap.containsKey(kind)) {
        seriesList.add(charts.Series<DebugLog, DateTime>(
            id: kind,
            // colorFn: (_, __) => charts.ColorUtil.fromDartColor(
            //     Color((Random().nextDouble() * 0xFFFFFF).toInt())
            //         .withOpacity(1.0)),
            domainFn: (DebugLog log, _) => log.time.toDate(),
            measureFn: (DebugLog log, _) => kinds[log.kind],
            data: groupedMap[kind]!));
      }
    }

    charts.SeriesRendererConfig<DateTime> renderer =
        charts.LineRendererConfig(includePoints: false);
    if (true) renderer = charts.BarRendererConfig<DateTime>();
    return charts.TimeSeriesChart(
      seriesList,
      animate: true,
      // barGroupingType: charts.BarGroupingType.groupedStacked,
      defaultInteractions: false,
      defaultRenderer: renderer,
      behaviors: [
        charts.SeriesLegend(position: charts.BehaviorPosition.top),
      ],
      // primaryMeasureAxis: charts.NumericAxisSpec(renderSpec: charts.NoneRenderSpec()),
      primaryMeasureAxis: new charts.NumericAxisSpec(showAxisLine: false),

      domainAxis: charts.DateTimeAxisSpec(
        viewport: charts.DateTimeExtents(
            start: DateTime.now().subtract(Duration(minutes: 30)),
            end: DateTime.now()),
        tickFormatterSpec: charts.AutoDateTimeTickFormatterSpec(
            hour: charts.TimeFormatterSpec(
                format: 'HH:mm', transitionFormat: 'HH:mm')),
        // tickProviderSpec:
        //     charts.AutoDateTimeTickProviderSpec(desiredTickCount: 10)
      ),
      layoutConfig: charts.LayoutConfig(
          leftMarginSpec: charts.MarginSpec.fixedPixel(65),
          rightMarginSpec: charts.MarginSpec.fixedPixel(25),
          topMarginSpec: charts.MarginSpec.fixedPixel(0),
          bottomMarginSpec: charts.MarginSpec.fixedPixel(35)),
    );
  }
}

/*
CharGPT指示

flutterで下記オブジェクトの配列を横軸時系列で表示するコードを生成
{time:DateTime, kind:string}

timeはfirestoreのDateTime型
クラス名はDebugLogChart, StatelessWidgetを継承
オブジェクトの配列はコンストラクタのパラメタで与える
chart_flutterパッケージ使用

凡例をつける、位置はtop X軸には時間の目盛りを表示,X軸の範囲は現在の時刻から30分前まで,形式はHH:mm
layoutConfigのマージンの最小値は左65,右25,上0,下35
グラフのタイトルや軸のラベルは不要
下記のケースでバーを表示する
kind=="INITIAL"の場合、値は10
kind=="RMM:POLLING1"の場合、値は1
kind=="RMM:POLLING2"の場合、値は5
kind=="RMM:MIB_INFO_REQUEST"の場合、値は10
kind=="RMM:MIB_INFO_RESULT"の場合、値は10

*/
