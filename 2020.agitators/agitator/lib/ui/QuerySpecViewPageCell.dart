import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:url_launcher/url_launcher.dart';

import 'AnimatedChip.dart';
import 'Common.dart';
import 'QuerySpecViewPage.dart';
import 'User.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

Widget defaultItemCell(
    BuildContext context,
    int index,
    QueryDocumentSnapshot itemDoc,
    dynamic querySpec,
    DocumentReference queryDocument) {
  Map<String, dynamic> data = itemDoc.data();

  List<String> getTypeFilter(Map<String, dynamic> q) {
    List<List<String>> f = (q["where"] as List<dynamic>?)
            ?.where((e) => e["field"] == "type" && e["op"] == "containsAny")
            .map((e) => (e["values"] as List).map((e) => e as String).toList())
            .toList() ??
        [];
    if (f.length == 0) return [];
    return f[0];
  }

  Map<String, dynamic> setTypeFilter(
      Map<String, dynamic> q, List<String> typeFilter) {
    if (typeFilter.length > 0) {
      Map<String, dynamic> newQuery = setTypeFilter(q, []);
      if (newQuery["where"] == null) newQuery["where"] = [];
      (newQuery["where"] as List).add({
        "field": "type",
        "op": "containsAny",
        "type": "list<string>",
        "values": typeFilter,
      });
      return newQuery;
    } else {
      return q.map((k, v) {
        return k == "where"
            ? MapEntry(
                k,
                (v as List)
                    .where(
                        (e) => e["field"] != "type" || e["op"] != "containsAny")
                    .toList())
            : MapEntry(k, v);
      });
    }
  }

  List<String> filterTypes = getTypeFilter(querySpec);

  List<Widget> chips = [];
  Widget chip(String typeName) => ChoiceChip(
        label: Text(typeName.split(".").last),
        selected: filterTypes.any((e) => e == typeName),
        onSelected: (isSelected) {
          isSelected ? filterTypes.add(typeName) : filterTypes.remove(typeName);
          queryDocument.set(setTypeFilter(querySpec, filterTypes));
        },
      );

  Widget timeChip(Map<String, dynamic> data) {
    int time = data["time"] ?? 0;
    return AnimatedChip(
        ago: DateTime.now().millisecondsSinceEpoch - time,
        builder: (_, color) {
          return Chip(
              label: Text(DateTime.fromMillisecondsSinceEpoch(time).toString()),
              backgroundColor: color.value);
        });
  }

  if (data["type"] is List)
    data["type"]?.forEach((typeName) => chips.add(chip(typeName)));

  List<Widget> menuButtonBuilder(BuildContext context) => [
        TextButton(
            child: Text("Actions"),
            onPressed: () {
              showDialog<String>(
                context: context,
                builder: (context) => SimpleDialog(
                  children: [
                    ["Open Sub-Collection [query]", "query"],
                    ["Open Sub-Collection [state]", "state"],
                    ["Open Sub-Collection [logs]", "logs"],
                  ]
                      .map((e) => SimpleDialogOption(
                          child: Text(e[0]),
                          onPressed: () => naviPop(context, e[1])))
                      .toList(),
                ),
              ).then((res) {
                if (res != null) {
                  naviPop(context);
                  naviPush(context, (_) {
                    itemDoc.reference.collection(res);
                    DocumentReference filter = appData("filter_$res");
                    filter.set({
                      "collection": "${itemDoc.reference.path}/$res",
                      "where": [
/*                  {
                    "field": "cluster",
                    "op": "==",
                    "type": "string",
                    "value": "G11"
                  }*/
                      ],
                      "limit": 50
                    });
                    return QuerySpecViewPage(queryDocument: filter);
                  });
                }
              });
            })
      ];

  String ipAddr = data["dev"]?["ip"] ?? "IP:UNK";
  return wrapDocumentOperationMenu(itemDoc, context,
      buttonBuilder: menuButtonBuilder,
      child: Card(
          color: Colors.grey[200],
          child: Padding(
            padding: EdgeInsets.all(3),
            child: Wrap(
                children: chips +
                    [
                      timeChip(data),
                      ActionChip(
                        label: Text(ipAddr),
                        backgroundColor: Colors.green[200],
                        onPressed: () {
                          launch(
                              "https://10.36.102.184:8086/VNCConverter/$ipAddr:5900/?locale=en&modelName=SC&ipAddress=$ipAddr");
                        },
                      ),
                      Text("$index: ${itemDoc.id}"),
                    ] +
                    [editableTagChip(context, itemDoc, "usertag0")]),
          )));
}
