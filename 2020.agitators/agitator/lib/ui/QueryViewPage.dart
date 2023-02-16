//import 'dart:html';

import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riotagitator/ui/Bell.dart';

import 'Common.dart';
import 'QuerySpecViewPage.dart';
import 'documentPage.dart';

class QueryViewPage extends StatelessWidget {
  QueryViewPage({
    required this.query,
    this.itemBuilder,
    this.appBar,
    this.floatingActionButton,
  });

  final Query query;

  final AppBar? appBar;
  final Widget? floatingActionButton;

  final Widget Function(BuildContext context, int index,
      AsyncSnapshot<QuerySnapshot> snapshots)? itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar ?? defaultAppBar(context),
      body: QueryViewWidget(
        query: query,
        itemBuilder: itemBuilder,
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  AppBar defaultAppBar(BuildContext context) {
    return AppBar(
      title: Text("${query.parameters} - Query"),
      actions: [bell(context)],
    );
  }

  FloatingActionButton defaultFloatingActionButton(
          BuildContext context, DocumentReference dRef) =>
      FloatingActionButton(
        child: Icon(Icons.note_add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DocumentPage(dRef)),
          );
        },
      );
}

// ignore: must_be_immutable
class QueryViewWidget extends StatelessWidget {
  QueryViewWidget({
    required this.query,
    this.itemBuilder,
  });

  final Query query;

   Widget Function(BuildContext context, int index,
      AsyncSnapshot<QuerySnapshot> snapshots)? itemBuilder;

  Widget defaultItemBuilder(
      BuildContext context, int index, AsyncSnapshot<QuerySnapshot> snapshots) {
    QueryDocumentSnapshot? e = snapshots.data?.docs[index];
    return Card(child: Text("$index: ${e?.id} ${e?.data()}"));
  }

  @override
  Widget build(BuildContext context) {
    return streamWidget(query, context);
  }

  Widget streamWidget(Query query, BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    return StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshots) {
          if (snapshots.hasError)
            return SelectableText("Snapshots Error: ${snapshots.toString()}");
          if (!snapshots.hasData)
            return Center(child: CircularProgressIndicator());
          QuerySnapshot querySnapshotData = snapshots.data!;
          return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: w ~/ 220,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                  childAspectRatio: 2.0),
              itemCount: snapshots.data?.size,
              itemBuilder: (BuildContext context, int index) {
                itemBuilder = itemBuilder ?? defaultCell;
                return Container(
                    child: InkResponse(
                  onLongPress: () {
                    print("long");
                  },
                  child: Dismissible(
                    key: Key(querySnapshotData.docs[index].id),
                    child: itemBuilder!(context, index, snapshots),
                    onDismissed: (_) =>
                        querySnapshotData.docs[index].reference.delete(),
                  ),
                ));
              });
        });
  }

  Widget defaultCell(
      BuildContext context, int index, AsyncSnapshot<QuerySnapshot> snapshots) {
    QueryDocumentSnapshot doc = snapshots.data!.docs[index];
    Map<String, dynamic> data = doc.data();
    DateTime time = DateTime.fromMillisecondsSinceEpoch(data["time"]);

    return wrapDocumentOperationMenu(doc, context,
        child: Card(
//          margin: EdgeInsets.all(3),
            color: Colors.black26,
            child: Padding(
              padding: EdgeInsets.all(3),
              child: Wrap(children: [
                Text(time.toString()),
                Text("$index: ${doc.id}"),
              ]),
            )));
  }

  Widget body(List<QueryDocumentSnapshot> docs, BuildContext context) {
    double w = MediaQuery.of(context).size.width;

    return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: w ~/ 160,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
            childAspectRatio: 2.0),
        itemCount: docs.length,
        itemBuilder: (BuildContext context, int index) {
          QueryDocumentSnapshot d = docs[index];

          return Container(
            child: InkResponse(
              onLongPress: () {
                print("long");
              },
              child: Dismissible(
                key: Key(docs[index].id),
//              child: buildGenericCard(context, dRef),
                onDismissed: (_) => docs[index].reference.delete(),
                child: Card(
                  color: Theme.of(context).cardColor,
                  child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.black26,
                      ),
                      child: GestureDetector(
                        child: Text(d.id, overflow: TextOverflow.ellipsis),
                        onTap: () => showDocumentOperationMenu(d.reference, context),
                      )),
                ),
              ),
            ),
          );
        });
  }

  AppBar defaultAppBar(BuildContext context) => AppBar(
      title: Text("${query.parameters} - Query"), actions: [bell(context)]);

  FloatingActionButton defaultFloatingActionButton(
          BuildContext context, DocumentReference dRef) =>
      FloatingActionButton(
        child: Icon(Icons.note_add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DocumentPage(dRef)),
          );
        },
      );
}

Query addFilter(Query query, dynamic filter) {
  dynamic parseValue(String op, var value) {
    if (op == "boolean") return value == "true";
    if (op == "number") return num.parse(value);
    if (op == "string") return value as String;
    if (op == "list<string>") return value.map((e) => e as String).toList();
    return null;
  }

  String filterOp = filter["op"];
  String field = filter["field"];
  String type = filter["type"];
  dynamic value = filter["value"];
  dynamic values = filter["values"];

  if (filterOp == "sort") {
    return query.orderBy(field, descending: value == "true");
  } else if (filterOp == "==") {
    return query.where(field, isEqualTo: parseValue(type, value));
  } else if (filterOp == "!=") {
    return query.where(field, isNotEqualTo: parseValue(type, value));
  } else if (filterOp == ">=") {
    return query.where(field, isGreaterThanOrEqualTo: parseValue(type, value));
  } else if (filterOp == "<=") {
    return query.where(field, isLessThanOrEqualTo: parseValue(type, value));
  } else if (filterOp == ">") {
    return query.where(field, isGreaterThan: parseValue(type, value));
  } else if (filterOp == "<") {
    return query.where(field, isLessThan: parseValue(type, value));
  } else if (filterOp == "notIn") {
    return query.where(field, whereNotIn: parseValue(type, value));
  } else if (filterOp == "in") {
    return query.where(field, whereIn: parseValue(type, values));
  } else if (filterOp == "contains") {
    return query.where(field, arrayContains: parseValue(type, value));
  } else if (filterOp == "containsAny") {
    return query.where(field, arrayContainsAny: parseValue(type, values));
  } else {
    throw Exception();
  }
}

Query addFilters(Query query, dynamic filterList) =>
    filterList.toList().fold(query, (a, e) => addFilter(a, e));

Query addOrderBy(Query query, dynamic order) =>
    query.orderBy(order["field"], descending: order["descending"] == true);
