import 'package:charts_flutter/flutter.dart' as charts;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:console_ft/main.dart';
import 'package:flutter/material.dart';

/*
CharGPT指示

コードを作って

flutterでfiresoreの下記のレコードのドキュメントをグラフ表示する

{"snmpLogs":[{"reqCount":1,"resCount":10,"time":12345}] }

横軸時系列の折れ線グラフ

上記をStreamBuilderを使ってリアルタイムに更新するようにして

複数のドキュメントのカウンタ情報を結合して一つのグラフにします

ページではなくグラフWidgetを生成して。既存ページに埋め込むので

Queryをコンストラクタで与えるように変更

@required は現在のflutterでは required キーワードでは?

上のfl_chartを使ったプログラムを、chart_flutterパッケージ使って書き換えて


* */

class SnmpCountChart extends StatefulWidget {
  final Query query;

  SnmpCountChart(this.query,{Key? key}) : super(key: key);

  @override
  _SnmpCountChartState createState() => _SnmpCountChartState();
}

class _SnmpCountChartState extends State<SnmpCountChart> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: widget.query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return loadingIcon();
        List<TimeSeriesSales> reqCountData = [];
        List<TimeSeriesSales> resCountData = [];
        snapshot.data!.docs.forEach((doc) {
          List<dynamic> snmpLog = doc['snmpLogs'];
          snmpLog.forEach((log) {
            reqCountData.add(TimeSeriesSales(DateTime.fromMillisecondsSinceEpoch(log['time']), log['reqCount']));
            resCountData.add(TimeSeriesSales(DateTime.fromMillisecondsSinceEpoch(log['time']), log['resCount']));
          });
        });
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: charts.TimeSeriesChart(
            [
              charts.Series<TimeSeriesSales, DateTime>(
                id: 'ReqCount',
                colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
                domainFn: (TimeSeriesSales sales, _) => sales.time,
                measureFn: (TimeSeriesSales sales, _) => sales.sales,
                data: reqCountData,
              ),
              charts.Series<TimeSeriesSales, DateTime>(
                id: 'ResCount',
                colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
                domainFn: (TimeSeriesSales sales, _) => sales.time,
                measureFn: (TimeSeriesSales sales, _) => sales.sales,
                data: resCountData,
              ),
            ],
            animate:false,
            dateTimeFactory:
            const charts.LocalDateTimeFactory(),
          ),
        );
      },
    );
  }
}

class TimeSeriesSales {
  final DateTime time;
  final int sales;

  TimeSeriesSales(this.time,this.sales);
}