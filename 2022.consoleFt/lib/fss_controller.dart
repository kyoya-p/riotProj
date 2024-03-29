import 'dart:collection';
import 'package:collection/collection.dart';
import 'package:console_ft/clock.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'document_editor.dart';
import 'main.dart';

// SNMP検索条件設定Widget
Widget fssControlerField(BuildContext context1, DocumentReference refDev) {
  return StreamBuilder<DocumentSnapshot>(
    stream: refDev.snapshots(),
    builder: (context, ssDev) {
      if (ssDev.data?.data() == null) return loadingIcon();
      final dev = ssDev.data?.data() as LinkedHashMap<dynamic, dynamic>;
      final refFssStorage = refDev.collection("storage").doc("data1");
      return StreamBuilder<DocumentSnapshot>(
          stream: refFssStorage.snapshots(),
          builder: (context, ssFssStorage) {
            if (ssFssStorage.data == null) return loadingIcon();
            var fssStorage = (ssFssStorage.data?.data() ?? {})
                as LinkedHashMap<dynamic, dynamic>;
            final initUrl =
                TextEditingController(text: dev["fssSpec"]["initUrl"]);
            final adr = TextEditingController(text: dev["fssSpec"]["adr"]);
            final pollItvl = TextEditingController(
                text: dev["fssSpec"]["pollInterval"].toString());

            final initUrlFiled = TextField(
                controller: initUrl,
                decoration: const InputDecoration(
                    label: Text("Initialize URL:"),
                    hintText: "Log in to the RMM site to obtain"),
                onSubmitted: (_) {
                  dev["fssSpec"]["initUrl"] = initUrl.text;
                  refDev.set(dev);
                });
            final targetSnmpAdrField = TextField(
                controller: adr,
                decoration: const InputDecoration(
                    label: Text("Target SNMP address:"),
                    hintText: "Basically enter the IP address of the MFP"),
                onSubmitted: (_) {
                  dev["fssSpec"]["adr"] = adr.text;
                  refDev.set(dev);
                });
            final pollItvlField = TextField(
                controller: pollItvl,
                decoration: const InputDecoration(
                    label: Text("Polling Interval[ms]:"),
                    hintText: "FSS default is 3600000[ms] (60[min])."),
                onSubmitted: (_) {
                  dev["fssSpec"]["pollInterval"] = int.parse(pollItvl.text);
                  refDev.set(dev);
                });
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                initUrlFiled,
                Row(
                  children: [
                    Expanded(child: targetSnmpAdrField),
                    Text("MIB report Periodical "),
                    // periodicMibReportSwitch(refDev),

                    Switch(
                      value:
                          (dev['fssSpec']['periodicMibReport'] as int? ?? 0) >
                              DateTime.now().millisecondsSinceEpoch,
                      onChanged: (newValue) {
                        if (newValue) {
                          refDev.update({
                            'fssSpec.periodicMibReport':
                                DateTime.now().millisecondsSinceEpoch +
                                    60 * 60 * 1000
                          });
                        } else {
                          refDev.update({'fssSpec.periodicMibReport': 0});
                        }
                      },
                      activeTrackColor: Colors.red[100],
                      activeColor: Colors.red,
                    ),
                  ],
                  mainAxisAlignment: MainAxisAlignment.start,
                ),
                Row(children: [
                  Expanded(child: pollItvlField),
                  PopupMenuButton<Function()>(
                    // icon: Icon(Icons.more_vert),
                    child: Row(children: [
                      Text("eFSS Actions"),
                      Icon(Icons.more_vert)
                    ]),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                          child: Text('FSS: Manual Polling'),
                          value: () => manualPolling(refDev)),
                      PopupMenuItem(
                          child: Text('eFSS: Request MIB Notify Schedules'),
                          value: () => downloadDeviceSetting(refDev)),
                      PopupMenuItem(
                          child: Text('eFSS: Upload Device Capability'),
                          value: () {}),
                    ],
                    onSelected: (value) => value(),
                  ),
                  // items: {"Polling": () => manualPolling(refDev)}),
                  // FilledButton(
                  //     child: const Text("Polling"),
                  //     onPressed: () => manualPolling(refDev)),
                  // FilledButton(
                  //     child: const Text("GetConf"),
                  //     onPressed: () => downloadDeviceSetting(refDev)),
                  FilledButton(
                      child: const Text("Clear Work Memory"),
                      onPressed: () => refFssStorage.delete()),
                  FilledButton(
                      child: const Text("Reboot"),
                      onPressed: () {
                        dev["time"] = getServerTime().millisecondsSinceEpoch;
                        refDev.set(dev);
                      })
                ]),
                InkWell(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Model Name: ${fssStorage["modelName"]}",
                              maxLines: 1),
                          Text("Serial Number: ${fssStorage["serialNumber"]}",
                              maxLines: 1),
                          Text("Polling URL: ${fssStorage["pollUrl"]}",
                              maxLines: 1),
                          Text("Alert URL: ${fssStorage["alertUrl"]}",
                              maxLines: 1),
                          Text("Notify URL: ${fssStorage["notifyUrl"]}",
                              maxLines: 1)
                        ]),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                DocumentPage(refFssStorage)))),
                mibReportScheduleControl(context, refFssStorage, fssStorage),
                // Expanded(child: RealtimeMetricsWidget(refDev)),
              ],
            );
          });
    },
  );
}

fssMenu() => PopupMenuButton<Function()>(
      // icon: Icon(Icons.more_vert),
      child: Row(children: [Text("eFSS Actions"), Icon(Icons.more_vert)]),
      itemBuilder: (context) => [
        PopupMenuItem(child: Text('Item 1'), value: () {}),
        PopupMenuItem(child: Text('Item 2'), value: () {}),
        PopupMenuItem(child: Text('Item 3'), value: () {}),
      ],
      onSelected: (value) => value(),
    );

/*
schedulesの要素の数だけボタンをRow方向に配置するWidgetを生成する関数
ドキュメントstorageの構造 {schedules: [{id:String, interval:int,oidList:[{oid:String,snmp:String}]}] }
intervalはミリ秒
schedulesの要素の数だけボタンをRow方向に配置
ボタンのラベルは、スケジュールのインデクス番号、intervalを秒単位で、oidListの要素数、それぞれの文字列を結合して"%{d}:%{d}sec[%{d}]"形式で表示
最新flutterのコード、null安全、@requiredではなくrequired

ボタンが押されたとき下記ダイアログを表示:
スケジュールの番号に対応する、インターバルを変更するダイアログを表示
数値フィールドの初期値はボタンに対応するスケジュールのinterval
OKをクリックした場合、ダイアログで設定した構造体のintervalを上書きし、ダイアログを閉じる
Cancelの場合は何もせずダイアログをクローズ

*/

Widget mibReportScheduleControl(
    BuildContext context, DocumentReference refFssStorage, dynamic fssStorage) {
  final scheds = fssStorage["schedules"] as List<dynamic>? ?? [];
  return Row(
    children: scheds.map((sched) {
      final ix = scheds.indexOf(sched);
      final d = Duration(milliseconds: sched['interval']);
      String label =
          "#${ix} ${d.inMilliseconds / 1000.0}s / ${sched['oidList'].length} mibs";
      return ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              // 初期値はスケジュールのinterval
              int interval = sched['interval'];
              return AlertDialog(
                title: Text("Interval of MIB schedule #$ix [ms]"),
                content: TextFormField(
                    initialValue: "$interval",
                    keyboardType: TextInputType.number,
                    onChanged: (value) => interval = int.parse(value)),
                actions: [
                  TextButton(
                      onPressed: () {
                        fssStorage["schedules"][ix]["interval"] = interval;
                        refFssStorage.set(fssStorage);
                        Navigator.pop(context);
                      },
                      child: Text("OK")),
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel")),
                ],
              );
            },
          );
        },
        child: Text(label),
      );
    }).toList(),
  );
}

/*
トグルスイッチWidgetを生成する関数
firestoreのドキュメント refFssSpec を参照し、periodicMibReport の値を反映させる。
refFssSpecが格納するドキュメント: {fssSpec:{periodicMibReport:boolean}}
periodicMibReport==trueの場合off, そうでない場合はon
ラベルは「変更ある場合のみMIBレポートを送信」
Dartはnull安全
*/
Widget periodicMibReportSwitch(DocumentReference refFssSpec) {
  return StreamBuilder<DocumentSnapshot>(
    stream: refFssSpec.snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        int value =
            snapshot.data?.get('fssSpec.periodicMibReport') as int? ?? 0;
        return Switch(
          value: value > DateTime.now().millisecondsSinceEpoch,
          onChanged: (newValue) {
            if (newValue) {
              refFssSpec.update({
                'fssSpec.periodicMibReport':
                    DateTime.now().millisecondsSinceEpoch
              });
            } else {
              refFssSpec.update({'fssSpec.periodicMibReport': 0});
            }
          },
          activeTrackColor: Colors.red[100],
          activeColor: Colors.red,
        );
      } else {
        // return CircularProgressIndicator();
        return noItem();
      }
    },
  );
}

manualPolling(DocumentReference refDev) {
  final refMachine = refDev.collection("ctrl").doc("machine");
  refMachine.set({"manualPolling": true});
}

downloadDeviceSetting(DocumentReference refDev) {
  final refMachine = refDev.collection("ctrl").doc("machine");
  refMachine.set({"downloadDeviceSetting": true});
}
