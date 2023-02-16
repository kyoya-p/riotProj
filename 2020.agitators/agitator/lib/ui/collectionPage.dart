import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riotagitator/ui/Bell.dart';

import 'QueryViewPage.dart';
import 'documentPage.dart';

/*
 Firestore Collectionを操作するWidget - AppBar
 - Documentの追加/削除
 - DocumentがTapされた時の動作
 */

// ignore: must_be_immutable
class CollectionPage extends StatelessWidget {
  CollectionPage(
    this.query, {
    this.cRef,
    this.itemBuilder,
    AppBar? appBar,
    this.floatingActionButton,
  });

  Query query;
  CollectionReference? cRef;
  AppBar? appBar;
  Widget? floatingActionButton;

  AppBar defaultAppBar(BuildContext context) => AppBar(
      title: Text("${cRef?.parameters} - Collection"),
      actions: [bell(context)]);

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

  Widget Function(BuildContext context, int index,
      AsyncSnapshot<QuerySnapshot> snapshots)? itemBuilder;

//
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar ?? defaultAppBar(context),
      body: QueryViewWidget(
        query: query,
        itemBuilder: itemBuilder,
      ),
      floatingActionButton: (cRef != null && floatingActionButton != null)
          ? defaultFloatingActionButton(context, cRef!.doc())
          : null,
    );
  }
}

/*
 Firestore Collectionを操作するWidget - コンテンツ部分
 - Documentの追加/削除
 - DocumentがTapされた時の動作
 */
/*
class FsCollectionOperatorWidget extends StatelessWidget {
  CollectionReference query;

  Widget Function(BuildContext context, int index,
      List<QueryDocumentSnapshot> snapshots) itemBuilder;

  Function(BuildContext context, int index, QuerySnapshot snapshots)? onTapItem;

  FsCollectionOperatorWidget(
      {required this.query, required this.itemBuilder, this.onTapItem = null}) {
    //_dbSnapshot = query.snapshots();
    if (itemBuilder == null) {
      itemBuilder = (context, index, docs) => Container(
            decoration: BoxDecoration(
              //border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(5),
              color: Theme.of(context).primaryColorLight,
            ),
            child: Row(children: [
              Icon(Icons.text_snippet_outlined),
              Text(docs[index].id)
            ]),
          );
    }
    if (onTapItem == null) {
      onTapItem = (context, index, snapshot) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    DocumentPage(snapshot.docs[index].reference!)
                //ObjectOperatorWidget(docRef: query.doc(docs[index].id)),
                ));
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;

    return StreamBuilder(
        stream: query.snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          QuerySnapshot snapshotData = snapshot.data!;
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: w ~/ 160,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                childAspectRatio: 2.0),
            itemCount: snapshotData.size,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                //child: GestureDetector(
                //onTap: () {
                //  onTapItem(context, index, snapshot);
                //},
                child: Dismissible(
                  key: Key(snapshotData.docs[index].id),
                  child: itemBuilder(context, index, snapshotData.docs),
                  onDismissed: (direction) {
                    //query.doc(snapshot.data.docs[index].id).delete();
                    //snapshot.data.docs[index].delete();
                  },
                ),
                //),
              );
            },
          );
        });
  }
}
*/
