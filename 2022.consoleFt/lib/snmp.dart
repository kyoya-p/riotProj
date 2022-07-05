import 'dart:async';

import 'package:console_ft/vmstatChart.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'type.dart';
import 'vmstat.dart';

DocumentReference<Map<String, dynamic>>? refApp;
DocumentReference<Map<String, dynamic>>? refDev;

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

Widget discResultField(Query docRefResult) {
  return StreamBuilder<QuerySnapshot>(
      stream: docRefResult.snapshots(),
      builder: (context, snapshot) {
        final docsDiskRes = snapshot.data?.docs
            .map((e) => DiscoveryRes(e.data() as Map<String, dynamic>))
            .toList();
        if (docsDiskRes == null) return loadingIcon();
        if (docsDiskRes.isEmpty) return noItem();
        return ListView.builder(
          scrollDirection: Axis.vertical,
          itemCount: docsDiskRes.length,
          itemBuilder: (context, index) {
            final e = docsDiskRes[index];
            return Container(
              height: 58,
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.print),
                  title: Text(
                      '${e.time.toDate().toLocal()} : : ${e.vbs.join(" : ")}'),
                  subtitle: Text(e.ip),
                ),
              ),
            );
          },
        );
      });
}

Widget discResultTable(Query docRefResult) {
  List<DataCell> card(int i, DiscoveryRes e) => [
        Text(e.time.toDate().toString(), maxLines: 1),
        Text(e.ip),
        //SizedBox(width: 200, child: Text(e.vbs[0], maxLines: 1)),
        Expanded(child: Text(e.vbs[0], maxLines: 1)),
        Text(e.id),
      ].map((e) => DataCell(e)).toList();
  return StreamBuilder<QuerySnapshot>(
      stream: docRefResult.snapshots(),
      builder: (context, ssDiscRes) {
        final docsDiskRes = ssDiscRes.data?.docs
            .map((e) => DiscoveryRes(e.data() as Map<String, dynamic>))
            .toList();
        if (docsDiskRes == null) return loadingIcon();
        if (docsDiskRes.isEmpty) return noItem();
        return SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text("Time")),
              DataColumn(label: Text("IP")),
              DataColumn(label: Text("Model")),
              DataColumn(label: Text("ID")),
            ],
            rows: docsDiskRes.map((e) => DataRow(cells: card(0, e))).toList(),
          ),
        );
      });
}

Widget loadingIcon() => const Center(child: CircularProgressIndicator());
Widget noItem() => const Center(child: Text("No item"));

// Sample OID
const hrDeviceDescr = "1.3.6.1.2.1.25.3.2.1.3";
const hrDeviceStatus = "1.3.6.1.2.1.25.3.2.1.5";
const hrDeviceErrors = "1.3.6.1.2.1.25.3.2.1.6";
