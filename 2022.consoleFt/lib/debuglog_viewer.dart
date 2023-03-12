import 'package:console_ft/types.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Widget expanded(Widget w) => Expanded(child: w);

class DebugLogsPage extends StatelessWidget {
  const DebugLogsPage(this.refDev, {Key? key}) : super(key: key);
  final DocumentReference refDev;
  @override
  Widget build(BuildContext context) {
    final refLogs =
        refDev.collection("reports").orderBy("time", descending: true);
    return Scaffold(
        appBar: AppBar(title: Text('${refDev.path} - Debug Logs')),
        body: PrograssiveListView2(refLogs, appendItems));
  }

  static ProgressiveListViewAppendItem appendItems =
      (ctx, vTgItem, vLog, i) => vLog.map((e) => Log(e.data())).forEach((e) {
            final vLog = e.debugLogs.toList();
            vLog.sort((a, b) =>
                b.time.millisecondsSinceEpoch - a.time.millisecondsSinceEpoch);
            for (var vmLog in vLog) {
              vTgItem.add(logItem(vmLog, vTgItem.length + 1));
            }
          });

  static Widget logItem(DebugLog e, int index) =>
      Text("$index: ${e.time.toDate()} [${e.kind}] ${e.log}");
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
    return Scrollbar(
      thumbVisibility: true,
      interactive: true,
      child: ListView.builder(itemBuilder: (context, index) {
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
            color: Theme.of(context).colorScheme.background,
            child: const Center(child: Text("End of Data")));
      }),
    );
  }
}
