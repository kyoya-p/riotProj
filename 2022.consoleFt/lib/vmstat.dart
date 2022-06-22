import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'main.dart';

Widget expanded(Widget w) => Expanded(child: w);

class VmstatPage extends StatelessWidget {
  const VmstatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (refDev == null) return loadingIcon();
    final refVmstat = refDev!
        .collection("vmstat")
        .orderBy("time", descending: true)
        .limit(12);

    return Scaffold(
        appBar: AppBar(title: Text('${refDev!.id} - vmstat')),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: refVmstat.snapshots(),
            builder: (context, snapshots) {
              if (!snapshots.hasData || snapshots.data!.docs.isEmpty) {
                return noItem();
              }
              final logs = snapshots.data!.docs;
              return ListView(
                  scrollDirection: Axis.vertical,
                  children: logs
                      .expand((e) => e.data()["logs"] as List<dynamic>)
                      .map((e) => Container(
                            decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(color: Colors.black38))),
                            child: ListTile(
                                leading: Text(
                                    '${(e["time"] as Timestamp).toDate().toLocal()}'),
                                title: Text('${e["log"]}')),
                          ))
                      .toList());
            }));
  }
}
