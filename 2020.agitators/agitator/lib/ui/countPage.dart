import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_auth/firebase_auth.dart';

import 'QuerySpecViewPage.dart';
import 'QueryBuilder.dart';
import 'Common.dart';

class DistributedCounter {
  DistributedCounter(this.queryCounters, this.countField) {
    queryCounters.snapshots().listen((snapshots) {
      int sum = snapshots.docs
          .fold<int>(0, (a, e) => a + e.data()[countField] as int);
      sc.sink.add(sum);
    });
  }

  final Query queryCounters;
  final String countField;
  StreamController<int> sc = StreamController();

  Stream<int> stream() => sc.stream;

  Future<T?> operation<T>(int distrRange, T Function(T?) op) async {

  }
}

Widget counter(BuildContext context, {String? counterFieldSpec}) {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final User user = FirebaseAuth.instance.currentUser;
  if (user.uid == null) return Center(child: CircularProgressIndicator());

  CollectionReference app1 = db.collection("user/${user.uid}/app1");
  DocumentReference docFilterAlerts = app1.doc("countLog");

  return StreamBuilder<DocumentSnapshot>(
    stream: docFilterAlerts.snapshots(),
    builder: (context, snapshot) {
      if (snapshot.data == null)
        return Center(child: CircularProgressIndicator());

      print("path=${snapshot.data!.data()}"); //TODO
      Map<String, dynamic> queryMap = snapshot.data!.data();
      Query query = QueryBuilder(queryMap).build()!;
      String counterField =
          counterFieldSpec ?? queryMap["countField"] ?? "count";
      DistributedCounter counter = DistributedCounter(query, counterField);

      return ActionChip(
        label: StreamBuilder(
            stream: counter.stream(),
            builder: (_, snapshot) => Text("${snapshot.data}")),

//        label: distributedCounter(context, query, counterField),
        //onPressed: () => showDocumentEditorDialog(context, docFilterAlerts),
        onPressed: () => naviPush(
            context, (_) => distributedCounterPage(_, docFilterAlerts)),
      );
    },
  );
}

Widget distributedCounter(
    BuildContext context, Query query, String counterField) {
  //QueryBuilder queryBuilder = QueryBuilder(snapshot.data());
  return StreamBuilder<QuerySnapshot>(
    stream: query.snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
      print("Cs[]=${snapshot.data?.size}"); //TODO
      var sum = snapshot.data?.docs
              .map((e) => e.data()?[counterField])
              .fold<int>(0, (a, e) => a + e as int) ??
          -9999;
      return Text("$sum");
    },
  );
}

Widget distributedCounterPage(
    BuildContext context, DocumentReference queryDoc) {
  Widget compactionButton = TextButton(
    child: Text("Compaction"),
    onPressed: () {},
  );

  Widget menus = PopupMenuButton<Function(BuildContext)>(
    itemBuilder: (BuildContext context) => [
      PopupMenuItem(
          child: Text("Compaction"),
          value: (BuildContext context) {
            showConfirmDialog(context, "Compaction these counters?", (context) {
              //compactDistributedCounter("count");
            });
          }),
    ],
    onSelected: (value) => value(context),
  );

  Widget page = QuerySpecViewPage(
    queryDocument: queryDoc,
    additionalActions: [menus, counter(context)],
  );

  return page;
}

compactDistributedCounter(Query queryCounters, String countField) {
  queryCounters.snapshots().listen((snapshots) {
    if (snapshots.size <= 1) return; // Error or no-need to operate
    int sum = snapshots.docs.fold<int>(0, (s, e) {
      return s + e.data()[countField]! as int;
    });
    print("sun=$sum"); //TODO
  });
}
