import 'package:console_ft/type.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

Widget expanded(Widget w) => Expanded(child: w);

class VmstatPage extends StatelessWidget {
  const VmstatPage(this.refDev, {Key? key}) : super(key: key);
//  final DocumentReference<Map<String, dynamic>> refDev;
  // final DocumentReference<Log> refDev;
  final DocumentReference refDev;
  @override
  Widget build(BuildContext context) {
    final refVmstat = refDev
        .collection("reports")
        .orderBy("time", descending: true)
        .limit(12);

    return Scaffold(
        appBar: AppBar(title: Text('${refDev.id} - Logs')),
        body: StreamBuilder<QuerySnapshot>(
            stream: refVmstat.snapshots(),
            builder: (context, snapshots) {
              final reports = snapshots.data?.docs.map((e) => Log(e.data()));
              final vmlogs = reports?.expand((log) => log.vmlogs).toList();
              if (vmlogs == null || vmlogs.isEmpty) return noItem();
              return ListView(
                  scrollDirection: Axis.vertical,
                  children: vmlogs
                      .map((e) => Container(
                            decoration: const BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(color: Colors.black38))),
                            child: ListTile(
                                leading: Text('${e.time.toDate().toLocal()}'),
                                title: Text(e.log)),
                          ))
                      .toList());
            }));
  }
}
