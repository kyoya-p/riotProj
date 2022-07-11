import 'package:console_ft/log_viewer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'main.dart';
import 'types.dart';

DocumentReference<Map<String, dynamic>>? refApp;

Widget discField(DocumentReference<Map<String, dynamic>> docRefAg) {
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
                  hintText: "スキャンごとの間隔 ミリ秒単位",
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
        final docsDiskRes = snapshot.data?.docs
            .map((e) => DiscoveryRes(e.data() as Map<String, dynamic>))
            .toList();
        if (docsDiskRes == null) return loadingIcon();
        if (docsDiskRes.isEmpty) return noItem();
        return ListView(
          children: docsDiskRes.map((e) => discResultItemMaker(e)).toList(),
        );
      });
}

Card discResultItemMaker(DiscoveryRes e) => Card(
        child: Row(children: [
      SizedBox(
          width: 180,
          child: Text(e.time.toDate().toIso8601String(), maxLines: 1)),
      SizedBox(width: 120, child: Text(e.ip, maxLines: 1)),
      Expanded(child: Text(e.vbs[0], maxLines: 1)),
    ]));

Widget discResultTable(Query docsRefResult) {
  ProgressiveListViewItemBuilder<DiscoveryRes> builder =
      (_, vItem, i) => discResultItemMaker(DiscoveryRes(vItem[i].data()));
  return PrograssiveListView<DiscoveryRes>(docsRefResult, builder);
}

// Sample OID
const hrDeviceDescr = "1.3.6.1.2.1.25.3.2.1.3";
const hrDeviceStatus = "1.3.6.1.2.1.25.3.2.1.5";
const hrDeviceErrors = "1.3.6.1.2.1.25.3.2.1.6";
