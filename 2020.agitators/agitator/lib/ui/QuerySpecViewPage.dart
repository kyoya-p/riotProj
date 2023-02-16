import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riotagitator/ui/Bell.dart';
import 'package:riotagitator/ui/QuerySpecViewPageCell.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:url_launcher/url_launcher.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_linkify/flutter_linkify.dart';

import 'Common.dart';
import 'QueryBuilder.dart';
import 'User.dart';
import 'collectionGroupPage.dart';
import 'collectionPage.dart';
import 'documentPage.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

// ignore: must_be_immutable
class QuerySpecViewPage extends StatelessWidget {
  QuerySpecViewPage({
    required this.queryDocument,
    this.itemBuilder,
    this.appBar,
    this.floatingActionButton,
    this.additionalActions,
  });

  final DocumentReference queryDocument;

  final AppBar? appBar;
  final Widget? floatingActionButton;
  final List<Widget>? additionalActions;

  final Widget Function(BuildContext context, int index,
      AsyncSnapshot<QuerySnapshot> snapshots)? itemBuilder;

  late QuerySpecViewWidget querySpecViewWidget;

  @override
  Widget build(BuildContext context) {
    querySpecViewWidget = QuerySpecViewWidget(
      queryDocument: queryDocument,
      itemBuilder: itemBuilder,
    );

    List<Widget> menuBuilder(BuildContext context) => [
          TextButton(
              child: Text("Samples"),
              onPressed: () {
                showDialog<String>(
                  context: context,
                  builder: (context) => SimpleDialog(
                      children: [
                    ["Query Sample1", "sample1"],
                  ]
                          .map((e) => SimpleDialogOption(
                              child: Text(e[0]),
                              onPressed: () {
                                naviPop(context);
                                showDocumentEditorDialog(context,
                                    db.doc("/apps/app1/sampleDocs/${e[1]}"));
                              }))
                          .toList()),
                );
              })
        ];

    Widget queryEditIcon(BuildContext context) => IconButton(
          icon: Icon(Icons.filter_list),
          onPressed: () => showDocumentEditorDialog(context, queryDocument,
              buttonBuilder: menuBuilder),
        );

    Widget deleteIcon(BuildContext context) => IconButton(
          icon: Icon(Icons.delete_forever),
          onPressed: () async {
            showConfirmDialog(context, "OK?", (_) {
              print("OK!!"); //TODO
              querySpecViewWidget.deleteItems(context);
              print("Complete!!"); //TODO
            });
          },
        );

    AppBar defaultAppBar(BuildContext context) {
      return AppBar(
        title: StreamBuilder<Map<String, dynamic>>(
          stream: querySpecViewWidget.querySpecStream.stream,
          builder: (context, snapshot) => Text(snapshot.data!["collectionGroup"] ??
              snapshot.data!["collection"]!),
        ),
        //titleX: Text("${querySpecViewWidget.querySpec} ${queryDocument.path} - Collection"),
        actions: (additionalActions ?? []) +
            [
              deleteIcon(context),
              queryEditIcon(context),
              bell(context),
            ],
      );
    }

    return Scaffold(
      appBar: appBar ?? defaultAppBar(context),
      body: querySpecViewWidget,
      floatingActionButton:
          floatingActionButton ?? defaultFloatingActionButton(context),
    );
  }

  FloatingActionButton defaultFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
        child: Icon(Icons.note_add),
        onPressed: () {
          queryDocument.get().then((dSs) {
            querySpecViewWidget.showDocumentEditDialog(context, null);
          });
        });
  }
}

// ignore: must_be_immutable
class QuerySpecViewWidget extends StatelessWidget {
  QuerySpecViewWidget({
    required this.queryDocument,
    this.itemBuilder,
  });

  final DocumentReference queryDocument;
  Map<String, dynamic>? querySpec;
  StreamController<Map<String, dynamic>> querySpecStream = StreamController();

  Widget Function(BuildContext context, int index,
      AsyncSnapshot<QuerySnapshot> snapshots)? itemBuilder;

  Widget defaultItemBuilder(
      BuildContext context, int index, AsyncSnapshot<QuerySnapshot> snapshots) {
    QueryDocumentSnapshot? e = snapshots.data?.docs[index];
    return Card(child: Text("$index: ${e?.id} ${e?.data()}"));
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<DocumentSnapshot>(
        stream: queryDocument.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.data == null)
            return Center(child: CircularProgressIndicator());
          querySpec = snapshot.data?.data();
          querySpecStream.sink.add(querySpec!);

          if (querySpec == null)
            return Center(child: Text("Query Error: ${snapshot.data?.data()}"));

          QueryBuilder q = QueryBuilder(snapshot.data!.data());
          return streamWidget(q.build()!, context);
        },
      );

  QuerySnapshot? querySnapshotData;

  Widget streamWidget(Query query, BuildContext context) =>
      StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshots) {
            if (snapshots.hasError)
              return SelectableText("Snapshots Error: ${snapshots.toString()}");
            if (!snapshots.hasData)
              return Center(child: CircularProgressIndicator());
            querySnapshotData = snapshots.data!;
            return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width ~/ 220,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 5,
                    childAspectRatio: 2.0),
                itemCount: snapshots.data?.size,
                itemBuilder: (BuildContext context, int index) {
                  itemBuilder = itemBuilder ??
                      (context, index, itemDoc) => defaultItemCell(
                          context,
                          index,
                          itemDoc.data!.docs[index],
                          querySpec,
                          queryDocument);
                  return Container(
                      child: InkResponse(
                    onLongPress: () {
                      print("long"); //TODO
                    },
                    child: Dismissible(
                      key: Key(querySnapshotData!.docs[index].reference.path),
                      //if these are 'id',there are conflict in collectionGroup
                      child: itemBuilder!(context, index, snapshots),
                      onDismissed: (_) {
                        print(
                            "Dismissed() ${querySnapshotData!.docs[index].reference.path}"); //TODO
                        querySnapshotData!.docs[index].reference.delete();
                      },
                    ),
                  ));
                });
          });

  deleteItems(BuildContext context) {
    if (querySpec == null || querySnapshotData == null) return;
    db.runTransaction((transaction) async {
      querySnapshotData!.docs.reversed.toList().asMap().forEach((i, e) {
        e.reference.delete().then((_) {
          print("Delete: $i: ${e.id}");
          /*ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Delete: $i: ${e.id}")),
          );
         */
        });
      });
    });
  }

  Widget body(List<QueryDocumentSnapshot> docs, BuildContext context) {
    double w = MediaQuery.of(context).size.width;

    return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: (w + 300) ~/ 300,
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
                        //onTap: () => showDocumentOperationMenu(d.reference, context),
                        onTap: () =>
                            showDocumentEditDialog(context, d.reference),
                      )),
                ),
              ),
            ),
          );
        });
  }

  showDocumentEditDialog(BuildContext context, DocumentReference? dRef) {
    if (querySpec == null) return;
    if (dRef == null) {
      CollectionReference? cRef = QueryBuilder(querySpec!).makeSimpleCollRef();
      if (cRef == null) return;
      dRef = cRef.doc();
    }
    List<Widget> menuButton(BuildContext context) => [
          TextButton(
              child: Text("Samples"),
              onPressed: () {
                showDocumentOperationMenu(dRef!, context);
              }),
          TextButton(
            child: Text("Actions"),
            onPressed: () {
              showDocumentOperationMenu(dRef!, context);
            },
          )
        ];
    showDocumentEditorDialog(context, dRef, buttonBuilder: menuButton);
  }
}

StreamBuilder filteredStreamBuilder(
    {required DocumentReference queryDocument,
    required Function(
            BuildContext context, AsyncSnapshot<QuerySnapshot> snapshots)
        builder}) {
  return StreamBuilder<DocumentSnapshot>(
    stream: queryDocument.snapshots(),
    builder: (context, snapshot) {
      if (snapshot.data == null)
        return Center(child: CircularProgressIndicator());
      print("query=${snapshot.data?.data()}"); //TODO

      Map<String, dynamic>? data = snapshot.data?.data();
      if (data == null)
        return Center(child: Text("Query Error: ${snapshot.data?.data()}"));

      QueryBuilder qb = QueryBuilder(snapshot.data!.data());
      return StreamBuilder<QuerySnapshot>(
        stream: qb.build()?.snapshots(),
        builder: (context, snapshot) => builder(context, snapshot),
      );
    },
  );
}

Widget editableTagChip(
    BuildContext context, QueryDocumentSnapshot ssDev, String tagName) {
  var tags = ssDev.data()?["tags"];
  String tagValue = (tags is Map) ? tags[tagName] : "";
  TextEditingController controller = TextEditingController(text: tagValue);

  updateTag(String value) {
    ssDev.reference.update({"tags.$tagName": value});
  }

  Widget hyperLync = Linkify(
    text: tagValue,
    onOpen: (link) async {
      if (await canLaunch(link.url)) {
        await launch(link.url);
      } else {
        throw 'Could not launch $link';
      }
    },
  );

  editTag() => showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
              title: Text('$tagName - Tag Value'),
              content: TextField(
                  controller: controller,
                  onSubmitted: (value) => updateTag(value)),
              actions: <Widget>[
                SimpleDialogOption(
                    child: Text('OK'),
                    onPressed: () {
                      updateTag(controller.text);
                      Navigator.pop(context);
                    }),
              ]));

  return Row(
    children: [
      IconButton(
        icon: Icon(Icons.edit, size: 20),
        onPressed: () => editTag(),
      ),
      hyperLync
    ],
  );
}

showDocumentOperationMenu(DocumentReference dRef, BuildContext context) {
  return showDialog(
    context: context,
    builder: (dialogCtx) {
      print("Dialog!!"); //TODO
      return SimpleDialog(
        title: Text(dRef.path),
        children: [
          SimpleDialogOption(
              child: Text("Publish (Update 'time' and set)"),
              onPressed: () {
                dRef.get().then((DocumentSnapshot doc) {
                  Map<String, dynamic> map = doc.data();
                  map["time"] = DateTime.now().toUtc().millisecondsSinceEpoch;
                  dRef.set(map);
                });
              }),
          SimpleDialogOption(
              child: Text("SubCollection: query"),
              onPressed: () {
                DocumentReference filter = appData("filter_DeviceQuery");
                filter.set({"collection": "${dRef.path}/query"});
                naviPop(context);
                naviPop(context);
                naviPush(
                  context,
                  (_) => QuerySpecViewPage(queryDocument: filter),
                );
              }),
          SimpleDialogOption(
              child: Text("SubCollection: results"),
              onPressed: () {
                Navigator.pop(dialogCtx);
                naviPush(
                    context, (_) => CollectionPage(dRef.collection("results")));
              }),
          SimpleDialogOption(
              child: Text("SubCollection: state"),
              onPressed: () {
                Navigator.pop(dialogCtx);
                DocumentReference filter = appData("filter_DeviceState");
                filter.set({"collection": "${dRef.path}/state"});
                naviPush(
                  context,
                  (_) => QuerySpecViewPage(queryDocument: filter),
                );
              }),
          SimpleDialogOption(
              child: Text("SubCollection: logs"),
              onPressed: () {
                Navigator.pop(dialogCtx);
                naviPush(
                  context,
                  (_) => CollectionGroupPage(dRef.collection("logs"),
                      filterConfigRef: appData("filterConfig")),
                );
              }),
        ],
      );
    },
  );
}

/* ================================================================================
    QuerySpecification for watchDocuments()
    {
      "collection": "collectionId",
      "subCollections": [ {"document":"documentId", "collection":"collectionId" }, ... ],

      "collectionGroup": "collectionGroupId",

      "orderBy": [
        { "field": "orderByFieldName",
          "descending": false  // true, false
        }//,...
      ],
      "where": [
        { "field":"filterFieldName",
          "op" : "==", // "==", "!=", ">", ">=", "<", "<=", "contains"
          "type": "number", // "number", "string", "boolean"
          "value": "fieldValue", // if with scalar-operator
        },
        { "field":"fieldName",
          "op" : "in", // "in", "notIn", "containsAny"
          "type": "list<string>", // "list<number>", "list<string>"
          "values": ["fieldValue1","fieldValue2",...] // if with list-operator
        }, ...
      ],

      "limit": 100
    }
  ================================================================================ */
