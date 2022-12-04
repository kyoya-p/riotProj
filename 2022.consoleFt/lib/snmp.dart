import 'dart:collection';
import 'dart:convert';

import 'package:console_ft/log_viewer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'main.dart';
import 'types.dart';

DocumentReference<Map<String, dynamic>>? refApp;

Widget discSettingField(DocumentReference<Map<String, dynamic>> docRefAg) {
  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRefAg.snapshots(),
      builder: (context, snapshot) {
        final docAg = SnmpScanner(snapshot.data?.data() ?? {});
        final tecIpSpec = TextEditingController(text: docAg.ipSpec);
        final tecInterval = TextEditingController(text: '${docAg.interval}');
        void updateDoc() {
          docAg.ipSpec = tecIpSpec.text;
          docAg.interval = int.parse(tecInterval.text);
          docRefAg.set(docAg.map);
        }

        return Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: TextField(
                controller: tecIpSpec,
                decoration: const InputDecoration(
                  label: Text("Scanning IP Range:"),
                  hintText: "スキャンIP範囲 例: 192.168.0.1-192.168.0.254",
                ),
                onSubmitted: (_) => updateDoc(),
              ),
            ),
            Expanded(
              child: TextField(
                controller: tecInterval,
                decoration: const InputDecoration(
                  label: Text("Interval:"),
                  hintText: "スキャンごとの間隔[msec]",
                ),
                onSubmitted: (_) => updateDoc(),
              ),
            ),
          ],
        );
      });
}

Widget listMonitor(Query docRefResult) {
  return StreamBuilder<QuerySnapshot>(
      stream: docRefResult.snapshots(),
      builder: (context, snapshot) {
        final docsDiscRes =
            snapshot.data?.docs.map((e) => DiscoveryRes(e.data())).toList();
        if (docsDiscRes == null) return loadingIcon();
        if (docsDiscRes.isEmpty) return noItem();
        return ListView(
          children: docsDiscRes.map((e) => discResultItemMaker(e)).toList(),
        );
      });
}

Object addVbToMap(Map<int, dynamic> map, List<int> oid, String v) {
  final key = oid[0];
  if (oid.length == 1) {
    map[key] = v;
  } else {
    map[key] = addVbToMap(map[key] ?? {}, oid.sublist(1), v);
  }
  return map;
}

Map<int, dynamic> addVbmToMap(Map<int, dynamic> map, Map<String, String> vbm) {
  for (final e in vbm.entries) {
    addVbToMap(map, oidToSeq(e.key).toList(), e.value);
  }
  return map;
}

Iterable<int> oidToSeq(String oid) => oid.split(".").map((e) => int.parse(e));
Widget errorList(Map<String, String> vbm) {
  final hrPrtErr = vbm[hrPrinterDetectedErrorState + ".1"];
  if (hrPrtErr == null) return const Text("");
  final hrPrtErrByte = utf8.encode(hrPrtErr);
  final flags0 = hrPrtErrByte[0].toRadixString(2).padLeft(8, '0');
  final flags1 = hrPrtErrByte[1].toRadixString(2).padLeft(8, '0');
  final vbl = addVbmToMap({}, vbm);
  final n = vbl.hrPrinterDetectedErrorState();
  print(n.firstDescendantsEntry());
  return Text("${flags0}_$flags1");
}

Card discResultItemMaker(DiscoveryRes e) => Card(
        child: Row(children: [
      SizedBox(
          width: 180,
          child: Text(e.time.toDate().toLocal().toString(), maxLines: 1)),
      SizedBox(width: 120, child: Text(e.ip, maxLines: 1)),
      Expanded(child: Text(e.vbs[0], maxLines: 1)),
      SizedBox(
        //width: 180,
        child: errorList(e.vbm),
      ),
    ]));

class DetectedDevicesPage extends StatelessWidget {
  const DetectedDevicesPage(this.refDev, {Key? key}) : super(key: key);
  final DocumentReference refDev;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${refDev.id} - Detected Devices')),
      body: DetectedDevicesWidget(refDev),
    );
  }
}

class DetectedDevicesWidget extends StatelessWidget {
  final DocumentReference refDev;
  const DetectedDevicesWidget(this.refDev, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final refvRes = refDev
        .collection("discovery")
        .orderBy("time", descending: true); //.limit(20);
    return PrograssiveListView2<DiscoveryRes>(
      refvRes,
      (context, vTgItem, vSrc, index) {
        vSrc.map((e) => DiscoveryRes(e.data())).forEach((e) {
          vTgItem.add(discResultItemMaker(e));
        });
      },
    );
  }
}

List<Widget> errorIcons(int hrPrinterDetectedErrorState) {
  Widget errorIcon(int i) {
    if (hrPrinterDetectedErrorState & (1 << i) != 0) {
      return Text('$i');
    } else {
      return const Text(" ");
    }
  }

  return List.generate(16, errorIcon);
}

const hrDeviceDescr = "1.3.6.1.2.1.25.3.2.1.3";
const hrDeviceStatus = "1.3.6.1.2.1.25.3.2.1.5";
const hrDeviceErrors = "1.3.6.1.2.1.25.3.2.1.6";
const hrPrinterDetectedErrorState = "1.3.6.1.2.1.25.3.5.1.2";
const sysDescr = "1.3.6.1.2.1.1.1";
const sysObjectID = "1.3.6.1.2.1.1.2";
const sysName = "1.3.6.1.2.1.1.5";
const sysLocation = "1.3.6.1.2.1.1.6";

extension VBLExt on dynamic {
  dynamic mib2() => this[1][3][6][1][2][1];
  dynamic hrPrinterDetectedErrorState() => this.mib2()[25][3][5][1][2];

  MapEntry<int, dynamic> firstChildEntry() =>
      SplayTreeMap<int, dynamic>.from(this as Map).entries.first;
  dynamic firstDescendantsEntry() {
    if (this.value is String) {
      return this;
    } else if (this.value is Map) {
      return this.firstChildEntry().value.firstDescendantsEntry();
    }
  }

  dynamic isNode() => this is Map;
  dynamic isLeaf() => this is String;
}
