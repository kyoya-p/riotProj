import 'dart:collection';
import 'dart:convert';

import 'package:console_ft/log_viewer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'main.dart';
import 'types.dart';

String escaped(String s) {
  return utf8.decode(utf8.encode(s).expand((e) {
    if (e <= 0x20 && 0x7f <= e || e == ':') {
      return utf8.encode(":${e & 0xff << 8}${e & 0xff}");
    } else {
      return [e];
    }
  }).toList());
}

DocumentReference<Map<String, dynamic>>? refApp;

// SNMP検索条件設定Widget
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

// SNMP検索結果表示(リアルタイム更新)Widget
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

// SNMP検索結果表示内の
Widget errorList(Map<String, String> vbm) {
  var status = "";
  final vbm2 = makeVBM(vbm);
  final hrDevSt = vbm2.firstDescendant(oidToList(hrDeviceStatus))?.value;
  final hrPrtSt = vbm2.firstDescendant(oidToList(hrPrinterStatus))?.value;
  status += "$hrDevSt/$hrPrtSt/";
  final hrPrtErr = vbm2.firstDescendant(oidToList(hrPrinterDetectedErrorState));
  if (hrPrtErr != null) {
    status += utf8
        .encode(hrPrtErr.value)
        .map((e) => e.toRadixString(2).padLeft(8, "0"))
        .join("_");
  }
  return Text("$status");
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
const hrPrinterStatus = "1.3.6.1.2.1.25.3.5.1.1";
const hrPrinterDetectedErrorState = "1.3.6.1.2.1.25.3.5.1.2";
const sysDescr = "1.3.6.1.2.1.1.1";
const sysObjectID = "1.3.6.1.2.1.1.2";
const sysName = "1.3.6.1.2.1.1.5";
const sysLocation = "1.3.6.1.2.1.1.6";

// Local VBL Library
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
List<int> oidToList(String oid) => oidToSeq(oid).toList();

extension VBMExt on SplayTreeMap<List<int>, String> {
  String? get(List<int> oid) => this[oid];
  MapEntry<List<int>, String>? getNext(List<int> oid) {
    final nextOid = firstKeyAfter(oid);
    if (nextOid == null) return null;
    final String? value = this[nextOid];
    if (value == null) return null;
    return MapEntry(nextOid, value);
  }

  List<int>? firstDescendantOid(List<int> oid) {
    bool startsWith(List<int> v, List<int> vTop) {
      if (vTop.length > v.length) return false;
      for (int i = vTop.length - 1; i >= 0; --i) {
        if (vTop[i] != v[i]) return false;
      }
      return true;
    }

    final nextOid = firstKeyAfter(oid);
    if (nextOid == null) return null;
    if (startsWith(nextOid, oid)) return nextOid;
    return null;
  }

  MapEntry<List<int>, String>? firstDescendant(List<int> oid) {
    final tgOid = firstDescendantOid(oid);
    if (tgOid == null) return null;
    final tgVal = this[tgOid];
    if (tgVal == null) return null;
    return MapEntry(tgOid, tgVal);
  }
}

SplayTreeMap<List<int>, String> makeVBM(Map<String, String> m) {
  int listComparetor(List<int> a, List<int> b) {
    if (a.length > b.length) {
      return -listComparetor(b, a);
    } else {
      for (int i = 0; i < a.length; ++i) {
        if (a[i] > b[i]) return 1;
        if (a[i] < b[i]) return -1;
      }
      if (a.length < b.length) return -1;
      return 0;
    }
  }

  final tgMap = SplayTreeMap<List<int>, String>(listComparetor);
  tgMap.addEntries(m.entries.map((e) {
    return MapEntry(oidToSeq(e.key).toList(), e.value);
  }));
  return tgMap;
}
