import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';

import 'Common.dart';
import 'documentPage.dart';
import 'QueryViewPage.dart';

/*
 Firestore CollectionGroupを表示するPage/Widget
 */

class CollectionGroupPage extends StatefulWidget {
  CollectionGroupPage(this.query, {this.filterConfigRef});

  final Query query;
  final DocumentReference? filterConfigRef;
  //final CollectionReference? containerOfNewDocument; //TODO

  @override
  _CollectionGroupPageState createState() => _CollectionGroupPageState();
}

class _CollectionGroupPageState extends State<CollectionGroupPage> {
  @override
  Widget build(BuildContext context) {
    IconButton filterButton = IconButton(
        icon: Icon(Icons.filter_list),
        onPressed: widget.filterConfigRef == null
            ? null
            : () => showFilterDialog(context)); // Dialog表示

    return Scaffold(
      appBar: AppBar(
        title: Text("CollectionGroup ${widget.query}"),
        actions: [filterButton],
      ),
      body: streamBuilderNotNull(widget.filterConfigRef),
    );
  }

  Widget? streamBuilderNotNull(DocumentReference? streamForFilter) {
    if (streamForFilter == null) return PrograssiveItemViewWidget(widget.query);
    return StreamBuilder<DocumentSnapshot>(
        stream: streamForFilter.snapshots(),
        builder: (context, _filterSnapshot) {
          if (!_filterSnapshot.hasData)
            return Center(child: CircularProgressIndicator());
          List<dynamic> filterList =
              _filterSnapshot.data?.data()["filter"] ?? [];
          return Column(children: [
            //FilterListConfigWidget(filterList),
            Expanded(
              child: PrograssiveItemViewWidget(
                  addFilters(widget.query, filterList)),
            ),
          ]);
        });
  }

  showFilterDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          DocumentWidget docWidget = DocumentWidget(widget.filterConfigRef!);
          TextButton applyButton = TextButton(
              onPressed: () => docWidget.setDocumentWithTime(context),
              child: Text("Apply"));
          TextButton closeButton = TextButton(
              onPressed: () => naviPop(context), child: Text("Close"));
          return AlertDialog(
            title: Row(children: [
              Text("Filter Setting"),
              sampleFiltersButton(context),
              applyButton,
              closeButton
            ]),
            content: docWidget,
          );
        });
  }

  Widget sampleFiltersButton(BuildContext context) {
    String sampleFilters = """
"Sort items by 'time' decending":
{"filter":[
  {"op":"sort", "field":"time", "type":"boolean", "value":"false"}
]}

"Select items which 'target:' is 'deviceA'":
{"filter":[
  {"op":"==", "field":"target", "type":"string", "value":"deviceA"}
]}

"Select items which 'time' is later than or equal 1612137600000 (2021-02-01 0:00:00 UTC) and earlier than 1612224000000 (2021-02-02 0:00:00 UTC).":
{"filter":[
  {"op":">=", "field":"time", "type":"number", "value":"1612137600000"},
  {"op":"<",  "field":"time", "type":"number", "value":"1612224000000"}
]}

"Select items which 'cluster' is 'clusterA' or 'clusterB'":
{"filter":[
  {"op":"in", "field":"cluster", "type":"list<string>", "values":["clusterA","clusterB"]}
]}

"Select items which 'tags' contains 'word'":
{"filter":[
  {"op":"contains", "field":"tags", "type":"string", "value":"word"}
]}

"Select items which 'tags' contains 'word1' or 'word2' ":
{"filter":[
  {"op":"containsAny", "field":"tags", "type":"list<string>", "values":["word1","word2"]}
]}

""";

    return TextButton(
      child: Text("Sample filters"),
      onPressed: () => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: SelectableText(sampleFilters),
        ),
      ),
    );
  }
}

// Firestoreで大きなリストを使う際のテンプレ
// ignore: must_be_immutable
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
            return buildListTile(index, widget.listDocSnapshot[index]);
          } else if (index > widget.listDocSnapshot.length) {
            return Text("");
          }
          widget.qrItems.limit(50).get().then((value) {
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

  Widget buildListTile(int index, DocumentSnapshot docSs) {
    Map<String, dynamic> doc = docSs.data();
    Widget padding = Padding(padding: EdgeInsets.only(left: 10));
    try {
      return Card(
          color: Theme.of(context).cardColor,
          child: GestureDetector(
            child: Row(children: [
              Text("$index"),
              padding,
              Text((doc["timeRec"] as Timestamp).toDate()?.toString() ??
                  "no data"),
              padding,
              Text(doc["dev"]?["id"] ?? "no data"),
              padding,
              Text(doc["dev"]?["type"] ?? "no data"),
              padding,
              Text(doc["seq"].toString()),
            ]),
            onTap: () =>
                naviPush(context, (_) => DocumentPage(docSs.reference)),
          ));
    } catch (e) {
      return Card(
          color: Colors.grey[200], //Theme.of(context).backgroundColor,
          child: GestureDetector(
            child: Row(children: [Text("$index"), padding, Text("$doc")]),
            onTap: () =>
                naviPush(context, (_) => DocumentPage(docSs.reference)),
          ));
    }
  }
}

/*
class FilterListConfigWidget extends StatelessWidget {
  FilterListConfigWidget(this.filterList);

  final List<dynamic> filterList;

  @override
  Widget build(BuildContext context) {
    try {
      //f (filterList == null) throw Exception();
    } catch (e, st) {
      print("Exception: $st");
    }

    return Column(
      children: filterList.map((e) => FilterConfigWidget(e)).toList(),
    );
  }
}

 */

class FilterConfigWidget extends StatefulWidget {
  FilterConfigWidget(this.filter);

  final dynamic filter;

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
