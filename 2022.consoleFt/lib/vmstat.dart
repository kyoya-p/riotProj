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
    final refVmstat = refDev!.collection("vmstat");

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
                children: logs.map((e)=>ListTile(title:Text('${e.data()}'))).toList(),
//                itemCount: logs.length,
//                itemBuilder: (context, index) => Text('$index'),
              );
            }));
  }
}
