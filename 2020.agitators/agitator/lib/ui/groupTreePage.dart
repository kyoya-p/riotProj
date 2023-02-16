//import 'dart:html';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riotagitator/login.dart';
import 'Common.dart';
import 'Bell.dart';
import 'QuerySpecViewPage.dart';
import 'countPage.dart';
import 'documentPage.dart';

final db = FirebaseFirestore.instance;

class GroupTreePage extends StatelessWidget {
  GroupTreePage({required this.user, this.tgGroup});

  final User user;
  final String? tgGroup;
  final bool v = false;

  @override
  Widget build(BuildContext context) {
    Query queryMyClusters = db.collection("group");
    queryMyClusters = queryMyClusters.where("users.${user.uid}.active",
        isEqualTo: true); //自身が管轄するすべてのgroup

    return Scaffold(
      appBar: AppBar(
        title: Text("$tgGroup - Group View"),
        actions: [
          globalGroupMenu(context),
          counter(context, counterFieldSpec: "count"),
          bell(context),
          loginButton(context)
        ],
      ),
      //drawer: appDrawer(context),
      body: StreamBuilder<QuerySnapshot>(
          stream: queryMyClusters.snapshots(),
          builder: (context, myClustersSnapshot) {
            if (myClustersSnapshot.data == null)
              return Center(child: CircularProgressIndicator());
            QuerySnapshot myClustersSnapshotData = myClustersSnapshot.data!;

            // 自分の属する全グループ
            Map<String, QueryDocumentSnapshot> myGrs = Map.fromIterable(
              myClustersSnapshotData.docs,
              key: (e) => e.id,
              value: (e) => e,
            );
            Map<String, QueryDocumentSnapshot> listedGrs;
            if (tgGroup == null) // topGroupが指定されていなければ自分の属する全グループのうち最上位のGroup
              listedGrs = Map.fromIterable(
                  myGrs.entries.where(
                      (e) => !myGrs.containsKey(e.value.data()["parent"])),
                  key: (e) => e.key,
                  value: (e) => e.value);
            else // topGroupが指定されていればそれに含まれるGroup
              listedGrs = Map.fromIterable(
                  myGrs.entries
                      .where((e) => e.value.data()["parent"] == tgGroup),
                  key: (e) => e.key,
                  value: (e) => e.value);
            return SingleChildScrollView(
                child: Column(
              children: [
                GroupTreeWidget(user: user, myGrs: myGrs, listGrs: listedGrs),
              ],
            ));
          }),

      floatingActionButton:
          (user.uid == null) ? null : floatingActionButtonBuilder(context),
    );
  }

  floatingActionButtonBuilder(BuildContext context) => FloatingActionButton(
      child: Icon(Icons.create_new_folder),
      onPressed: () async {
        naviPush(
            context,
            (_) => DocumentPage(db.collection("group").doc("__GroupID__"))
              ..setDocWidget.textDocBody.text = """
{
  "id": "__GroupID__",
  "type":["group","group.cluster"],
  "users":{
    "${firebaseAuth.currentUser.uid}":{"active":true}
  },
  "parent":"__ParentGroupId__"
}""");
      });
}

class GroupTreeWidget extends StatelessWidget {
  GroupTreeWidget(
      {required this.user, required this.myGrs, required this.listGrs});

  final User user;
  final Map<String, QueryDocumentSnapshot> myGrs;
  final Map<String, QueryDocumentSnapshot> listGrs;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          //borderRadius: BorderRadius.circular(5),
          //color: Colors.brown[100],
          ),
      child: Column(
        children: listGrs.entries.map((e) {
          return Dismissible(
            key: Key(e.value.id),
            child: GroupWidget(user: user, myGrs: myGrs, group: e.value),
            onDismissed: (_) {
              e.value.reference.delete();
            },
          );
        }).toList(),
      ),
    );
  }
}

class GroupWidget extends StatelessWidget {
  GroupWidget({required this.user, required this.myGrs, required this.group});

  final User user;
  final Map<String, QueryDocumentSnapshot> myGrs;
  final QueryDocumentSnapshot group;

  @override
  Widget build(BuildContext context) {
    Map<String, QueryDocumentSnapshot> subGrs = Map.fromEntries(
        myGrs.entries.where((e) => e.value.data()["parent"] == group.id));

    return GestureDetector(
      onTap: () {
        if (isTypeCluster(group))
          return naviPush(
            context,
//                (_) => ClusterViewerPage(clusterId: group.id),
            (_) {
              DocumentReference filter =
                  db.doc("user/${user.uid}/app1/filter_ClusterView");
              filter.set({
                "collection": "device",
                "where": [
                  {
                    "field": "cluster",
                    "op": "==",
                    "type": "string",
                    "value": group.id
                  }
                ],
                "limit": 100
              });
              return QuerySpecViewPage(queryDocument: filter);
            },
          );
        else
          return naviPush(
            context,
            (_) => GroupTreePage(user: user, tgGroup: group.id),
          );
      },
      onLongPress: () => showDocumentOperationMenu(group.reference, context),
      child: Padding(
        padding: EdgeInsets.only(left: 0, top: 0, right: 0, bottom: 0),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white, width: 2.0),
              left: BorderSide(color: Colors.white, width: 2.0),
            ),
            color: isTypeCluster(group)
                ? Theme.of(context).primaryColor.withOpacity(0.7)
                : Theme.of(context).primaryColor.withOpacity(0.1),
          ),
          //elevation: 4,
          /*color: group.data().getNested(["type", "group", "cluster"]) != null
              ? Theme.of(context).focusColor
              : Theme.of(context).cardColor,
          */
          child: Column(children: [
            Row(
              children: [Text("${group.id}")],
            ),
            Padding(
              padding:
                  EdgeInsets.only(left: 24.0, top: 36, right: 0, bottom: 0),
              child: GroupTreeWidget(user: user, myGrs: myGrs, listGrs: subGrs),
            ),
          ]),
        ),
      ),
    );
  }

  bool isTypeCluster(QueryDocumentSnapshot group) {
    var type = group.data()["type"];
    if (type is Map) {
      //Old style
      return group.data().getNested(["type", "group", "cluster"]) != null;
    } else if (type is List) {
      return type.contains("group.cluster");
    } else {
      return false;
    }
  }
}

extension ColorExt on Color {
  Color scale(double v) => Color.fromARGB(this.alpha, (this.red * v).toInt(),
      (this.green * v).toInt(), (this.blue * v).toInt());

  Color shift(int r, int g, int b) =>
      Color.fromARGB(this.alpha, this.red + r, this.green + g, this.blue + b);
}
