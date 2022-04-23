/*

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:riotagitator/ui/Common.dart';
import 'documentPage.dart';

class DeviceLogsPage_X extends StatefulWidget {
  DeviceLogsPage_X(this.logsRef, this.filterConfigRef);

  CollectionReference logsRef;
  DocumentReference filterConfigRef;

  @override
  _DeviceLogsPageState createState() => _DeviceLogsPageState();
}

class _DeviceLogsPageState extends State<DeviceLogsPage_X> {
  @override
  Widget build(BuildContext context) {
    User user = FirebaseAuth.instance.currentUser;
    DocumentReference filterRef = FirebaseFirestore.instance
        .collection("user")
        .doc(user.uid)
        .collection("app1")
        .doc("filterConfig");
    return Scaffold(
      appBar: AppBar(title: Text("Log Viewer")),
      body: StreamBuilder<DocumentSnapshot>(
          stream: filterRef.snapshots(),
          builder: (context, _filterSnapshot) {
            if (!_filterSnapshot.hasData)
              return Center(child: CircularProgressIndicator());
            List<dynamic> filterList =
                _filterSnapshot.data?.data()["filter"] ?? [];
            return Column(children: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  naviPush(context, (_) => DocumentPage(filterRef));
                },
              ),
              FilterListConfigWidget(filterList),
              Expanded(
                child: PrograssiveItemViewWidget(
                    widget.logsRef.addFilters(filterList)),
              ),
            ]);
          }),
    );
  }
}


// QueryにFilterを追加する拡張関数
extension QueryOperation on Query {
  dynamic parseValue(String type, String value) {
    if (type == "boolean") return value == "true";
    if (type == "number") return num.parse(value);
    if (type == "string") return value;
    return null;
  }

  Query addFilters(List<dynamic> filterList) {
    return filterList.fold(this, (a, e) {
      String filterOp = e["op"];
      String field = e["field"];
      String value = e["value"];
      String type = e["type"];

      if (filterOp == "sort") {
        return a.orderBy(field, descending: value == "true");
      } else if (filterOp == "==") {
        return a.where(field, isEqualTo: parseValue(type, value));
      } else if (filterOp == ">=") {
        return a.where(field, isGreaterThanOrEqualTo: parseValue(type, value));
      } else if (filterOp == "<=") {
        return a.where(field, isLessThanOrEqualTo: parseValue(type, value));
      } else if (filterOp == ">") {
        return a.where(field, isGreaterThan: parseValue(type, value));
      } else if (filterOp == "<") {
        return a.where(field, isLessThan: parseValue(type, value));
      } else {
        throw Exception();
      }
    });
  }
}


// Firestoreで大きなリストを使う際のテンプレ
class PrograssiveItemViewWidget extends StatefulWidget {
  PrograssiveItemViewWidget(this.qrItems);

  Query qrItems;
  List<DocumentSnapshot> listDocSnapshot = [];

  @override
  _PrograssiveItemViewWidgetState createState() =>
      _PrograssiveItemViewWidgetState();
}

class _PrograssiveItemViewWidgetState extends State<PrograssiveItemViewWidget> {
  @override
  void dispose() {
    widget.listDocSnapshot = [];
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: null, //widget.itemCount,
        itemBuilder: (context, index) {
          if (index < widget.listDocSnapshot.length) {
            return buildListTile(index, widget.listDocSnapshot[index].data());
          } else if (index > widget.listDocSnapshot.length) {
            return Text("");
          }
          widget.qrItems.limit(20).get().then((value) {
            if (mounted) {
              setState(() {
                if (value.size > 0) {
                  widget.listDocSnapshot.addAll(value.docs);
                  widget.qrItems =
                      widget.qrItems.startAfterDocument(value.docs.last);
                } else {}
              });
            }
          });
          //return Center(child: CircularProgressIndicator());
          return Card(
              color: Theme.of(context).disabledColor,
              child: Center(child: Text("End of Data")));
        });
  }

  Widget buildListTile(int index, Map<String, dynamic> doc) {
    Widget padding = Padding(padding: EdgeInsets.only(left: 10));
    try {
      return Card(
        color: Theme.of(context).cardColor,
        child: Row(children: [
          Text("$index"),
          padding,
          Text((doc["timeRec"] as Timestamp).toDate()?.toString() ?? "no data"),
          padding,
          Text(doc["dev"]?["id"] ?? "no data"),
          padding,
          Text(doc["dev"]?["type"] ?? "no data"),
          padding,
          Text(doc["seq"].toString()),
        ]),
      );
    } catch (e) {
      return Card(
          color: Colors.grey[200], //Theme.of(context).backgroundColor,
          child: Row(
              children: [Text("$index"), padding, Text("$doc")]));
    }
  }
}

class FilterListConfigWidget extends StatelessWidget {
  FilterListConfigWidget(this.filterList);

  List<dynamic> filterList;

  @override
  Widget build(BuildContext context) {
    try {
      if (filterList == null) throw Exception();
    } catch (e, st) {
      print("Exception: $st");
    }

    return Column(
      children: filterList.map((e) => FilterConfigWidget(e)).toList(),
    );
  }
}

class FilterConfigWidget extends StatefulWidget {
  FilterConfigWidget(this.filter);

  dynamic filter;

  @override
  State<StatefulWidget> createState() => _FilterConfigWidgetStatus();
}

class _FilterConfigWidgetStatus extends State<FilterConfigWidget> {
  String filterOperator = "";
  TextEditingController filterField = TextEditingController();
  String filterValType = "";
  TextEditingController filterValue = TextEditingController();

  @override
  Widget build(BuildContext context) {
    filterOperator = widget.filter["op"] ?? "sort";
    filterField.text = widget.filter["field"] ?? "timeRec";
    filterValType = widget.filter["type"] ?? "boolean";
    filterValue.text = widget.filter["value"] ?? "false";

    return Row(
      children: [
        Expanded(
            child: TextField(
          controller: filterField,
          decoration: InputDecoration(labelText: "Field"),
        )),
        Expanded(
          child: DropdownButton<String>(
            hint: Icon(Icons.send),
            value: filterOperator,
            icon: Icon(Icons.arrow_drop_down),
            onChanged: (newValue) {
              if (newValue != null)
                setState(() {
                  filterOperator = newValue;
                });
            },
            items: ['sort', '==', '>', '>=', '<=', '<']
                .map((String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: DropdownButton<String>(
            value: filterValType,
            icon: Icon(Icons.arrow_drop_down),
            onChanged: (newValue) {
              if (newValue != null)
                setState(() {
                  filterValType = newValue;
                });
            },
            items: ['number', 'string', 'boolean']
                .map((String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ))
                .toList(),
          ),
        ),
        Expanded(
            child: TextField(
          controller: filterValue,
          decoration: InputDecoration(labelText: "Value"),
        )),
      ],
    );
  }
}
*/