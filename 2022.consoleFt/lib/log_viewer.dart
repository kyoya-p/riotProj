import 'package:console_ft/types.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'snmp.dart';

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

// Firestoreで大きなリストを使う際のテンプレ

typedef ProgressiveListViewItemBuilder<T> = Widget Function(
    BuildContext context, List<QueryDocumentSnapshot> vItem, int index);

class PrograssiveListView<T> extends StatefulWidget {
  const PrograssiveListView(this.qrItemsInit, this.itemBuilder, {Key? key})
      : super(key: key);

  final Query qrItemsInit;
  final ProgressiveListViewItemBuilder<T> itemBuilder;

  @override
  _PrograssiveListViewState createState() => _PrograssiveListViewState();
}

class _PrograssiveListViewState<T> extends State<PrograssiveListView<T>> {
  List<QueryDocumentSnapshot> vSnapshotItem = [];
  late Query<T> qrItems = widget.qrItemsInit as Query<T>;
  _PrograssiveListViewState();

  @override
  void dispose() {
    vSnapshotItem = [];
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(itemBuilder: (context, index) {
      if (index < vSnapshotItem.length) {
        return widget.itemBuilder(context, vSnapshotItem, index);
      } else if (index > vSnapshotItem.length) {
        return const Text("");
      }
      qrItems.limit(20).get().then((v) {
        if (mounted && v.size > 0) {
          setState(() {
            vSnapshotItem.addAll(v.docs);
            qrItems = qrItems.startAfterDocument(v.docs.last);
          });
        }
      });
      //return Center(child: CircularProgressIndicator());
      return Card(
          color: Theme.of(context).disabledColor,
          child: const Center(child: Text("End of Data")));
    });
  }
}
