import 'package:console_ft/types.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

Widget expanded(Widget w) => Expanded(child: w);

class LogsPage extends StatelessWidget {
  const LogsPage(this.refDev, {Key? key}) : super(key: key);
  // final DocumentReference<Map<String, dynamic>> refDev;
  // final DocumentReference<Log> refDev;
  final DocumentReference refDev;
  @override
  Widget build(BuildContext context) {
    final refLogs =
        refDev.collection("reports").orderBy("time", descending: true);
    return Scaffold(
        appBar: AppBar(title: Text('${refDev.id} - Logs')),
        body: StreamBuilder<QuerySnapshot>(
            stream: refLogs.snapshots(),
            builder: (context, snapshots) {
              final reports = snapshots.data?.docs.map((e) => Log(e.data()));
              final vmlogs = reports?.expand((log) => log.vmlogs).toList();
              if (vmlogs == null || vmlogs.isEmpty) return noItem();
              return PrograssiveListView2(
                refLogs,
                appendItems,
              );
            }));
  }

  static ProgressiveListViewAppendItem appendItems =
      (ctx, vTgItem, vLog, i) => vLog.map((e) => Log(e.data())).forEach((e) {
            final vVmLog = e.vmlogs.toList();
            vVmLog.sort(
              (a, b) =>
                  b.time.millisecondsSinceEpoch - a.time.millisecondsSinceEpoch,
            );
            for (var vmLog in vVmLog) {
              vTgItem.add(vmstatLogItem(vmLog, vTgItem.length + 1));
            }
          });

  static Card vmstatLogItem(VmLog e, int index) => Card(
          child: Row(children: [
        SizedBox(width: 40, child: Text('$index')),
        SizedBox(
            width: 180,
            child: Text(e.time.toDate().toLocal().toString(), maxLines: 1)),
        Expanded(child: Text(e.log, maxLines: 1)),
      ]));
}

// Firestoreで大きなリストを使う際のテンプレ
typedef ProgressiveListViewItemBuilder<T> = Widget Function(
    BuildContext context, List<QueryDocumentSnapshot> vItem, int index);

class PrograssiveListView1<T> extends StatefulWidget {
  const PrograssiveListView1(this.qrItemsInit, this.itemBuilder, {Key? key})
      : super(key: key);

  final Query qrItemsInit;
  final ProgressiveListViewItemBuilder<T> itemBuilder;

  @override
  _PrograssiveListView1State createState() => _PrograssiveListView1State();
}

class _PrograssiveListView1State<T> extends State<PrograssiveListView1<T>> {
  List<QueryDocumentSnapshot> vSnapshotItem = [];
  late Query<T> qrItems = widget.qrItemsInit as Query<T>;
  _PrograssiveListView1State();

  @override
  void dispose() {
    vSnapshotItem = [];
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
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
        return Card(
            color: Theme.of(context).disabledColor,
            child: const Center(child: Text("End of Data")));
      },
    );
  }
}

// Firestoreで大きなリストを使う際のテンプレ(Widgetをリストに保持)
typedef ProgressiveListViewAppendItem = Function(BuildContext context,
    List<Widget> vTgItem, List<QueryDocumentSnapshot> vSrc, int index);

class PrograssiveListView2<T> extends StatefulWidget {
  const PrograssiveListView2(this.qrItemsInit, this.appendItems, {Key? key})
      : super(key: key);

  final Query qrItemsInit;
  final ProgressiveListViewAppendItem appendItems;

  @override
  _PrograssiveListView2State createState() => _PrograssiveListView2State();
}

class _PrograssiveListView2State<T> extends State<PrograssiveListView2> {
  List<Widget> vItem = [];
  late Query qrItems = widget.qrItemsInit;
  _PrograssiveListView2State();

  @override
  void dispose() {
    vItem = [];
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(itemBuilder: (context, index) {
      if (index < vItem.length) {
        return vItem[index];
      } else if (index > vItem.length) {
        return const Text("");
      }
      final q = qrItems.limit(20);
      q.get().then((v) {
        if (mounted && v.size > 0) {
          setState(() {
            widget.appendItems(context, vItem, v.docs, index);
            qrItems = qrItems.startAfterDocument(v.docs.last);
          });
        }
      });

      return Card(
          color: Theme.of(context).backgroundColor,
          child: const Center(child: Text("End of Data")));
    });
  }
}
