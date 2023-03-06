import 'dart:collection';
import 'dart:convert';

import 'package:console_ft/document_editor.dart';
import 'package:console_ft/vmlog_viewer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

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
Widget discSettingField(DocumentReference docRefAg) {
  return StreamBuilder<DocumentSnapshot>(
      stream: docRefAg.snapshots(),
      builder: (context, snapshot) {
        final docAg = snapshot.data?.data() as Map<String, dynamic>;
        final scanner = SnmpScanner(docAg);
        final tecIpSpec = TextEditingController(text: scanner.ipSpec);
        final tecInterval = TextEditingController(text: '${scanner.interval}');
        void updateDoc() {
          scanner.ipSpec = tecIpSpec.text;
          scanner.interval = int.parse(tecInterval.text);
          docRefAg.set(scanner.map);
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
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
Widget listMonitor(BuildContext context, Query docRefResult) {
  return StreamBuilder<QuerySnapshot>(
      stream: docRefResult.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.data == null) return loadingIcon();
        if (snapshot.data!.docs.isEmpty) return noItem();
        return ListView(
          children:
              // docsDiscRes.map((e) => discResultItemMaker(context, e)).toList(),
              snapshot.data!.docs
                  .map((e) => discResultItemMaker(context, e))
                  .toList(),
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
  return Text(status);
}

Widget discResultItemMaker(BuildContext context, QueryDocumentSnapshot e) {
  final d = DiscoveryRes(e.data());
  return InkWell(
    child: Card(
        child: Row(children: [
      SizedBox(
          width: 180,
          child: Text(
              DateTime.fromMillisecondsSinceEpoch(d.time).toLocal().toString(),
              maxLines: 1)),
      if (d.id != null)
        SizedBox(width: 240, child: Text("${d.id}", maxLines: 1)),
      if (d.ip != null)
        SizedBox(width: 120, child: Text("${d.ip}", maxLines: 1)),
      const TextButton(onPressed: null, child: Text("FSS")),
      //if (e.vbs != null) Expanded(child: Text("${e.vbs![0]}", maxLines: 1)),
      if (false)
        SizedBox(
          //width: 180,
          child: InkWell(
              onTap: () => showDialog(
                  context: context,
                  builder: (buildContext) => AlertDialog(
                        title: Text("SNMP Status"),
                        content: Text(
                          snmpStatusInfo,
                          style: GoogleFonts.courierPrime(),
                        ),
                      )),
              child: errorList(d.vbm ?? {})),
        ),
    ])),
    onTap: () {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => DocumentPage(e.reference)));
    },
  );
}

const snmpStatusInfo =
    """hrDeviceStatus/hrPrinterStatus/hrPrinterDetectedErrorState

hrDeviceStatus:
- unknown(1)
- running(2)
- warning(3)
- testing(4)
- down(5)
  
hrPrinterStatus:
- other(1)
- unknown(2)
- idle(3)
- printing(4)
- warmup(5)

hrPrinterDetectedErrorState:
- lowPaper(bit0)                 10000000_00000000
- noPaper(bit1)                  01000000_00000000
- lowToner(bit2)                 00100000_00000000
- noToner(bit3)                  00010000_00000000
- doorOpen(bit4)                 00001000_00000000
- jammed(bit5)                   00000100_00000000
- offline(bit6)                  00000010_00000000
- serviceRequested(bit7)         00000001_00000000
  
- inputTrayMissing(bit8)         00000000_10000000
- outputTrayMissing(bit9)        00000000_01000000
- markerSupplyMissing(bit10)     00000000_00100000
- outputNearFull(bit11)          00000000_00010000
- outputFull(bit12)              00000000_00001000
- inputTrayEmpty(bit13)          00000000_00000100
- overduePreventMaint(bit14)     00000000_00000010
""";

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
        .collection("devices")
        .orderBy("time", descending: true); //.limit(20);
    return PrograssiveListView2<DiscoveryRes>(
      refvRes,
      (context, vTgItem, vSrc, index) {
        vSrc.forEach((e) => vTgItem.add(discResultItemMaker(context, e)));
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
