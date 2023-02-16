import 'dart:convert';

import 'package:flutter/material.dart';
// import 'package:flutter/cupertino.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';

// import 'common.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

// Document編集Widget
class DocumentPage extends StatelessWidget {
  DocumentPage(DocumentReference dRef, {this.isIdEditable = true})
      : setDocWidget = DocumentWidget(dRef, isIdEditable: isIdEditable);

  final bool isIdEditable;
  final DocumentWidget setDocWidget;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${setDocWidget.docPath.text} - Document")),
      body: setDocWidget,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.send),
        onPressed: () => setDocWidget.setDocumentWithTime(context),
      ),
    );
  }
}

pushDocEditor(BuildContext context, DocumentReference docRef) => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DocumentPage(docRef)),
    );

class DocumentWidget extends StatefulWidget {
  DocumentWidget(DocumentReference documentRef, {this.isIdEditable = false})
      : docPath = TextEditingController(text: documentRef.path);

  final TextEditingController textDocBody = TextEditingController(text: "");
  final TextEditingController docPath;
  final bool isIdEditable;

  setDocumentWithTime(BuildContext context) {
    try {
      dynamic newDoc = JsonDecoder().convert(textDocBody.text);
      newDoc["time"] = DateTime.now().toUtc().millisecondsSinceEpoch;
      FirebaseFirestore.instance.doc(docPath.text).set(newDoc).then((_) {
//                  Navigator.pop(context);
        // ignore: return_of_invalid_type_from_catch_error
      }).catchError((e) => showAlertDialog(
          context,
          // ignore: return_of_invalid_type_from_catch_error
          Text(
              "${e.message}\nReq:${docPath.text}\nBody: ${textDocBody.text}")));
    } catch (ex) {
      showAlertDialog(context, Text(ex.toString()));
    }
  }

  @override
  _DocumentWidgetState createState() => _DocumentWidgetState();
}

class _DocumentWidgetState extends State<DocumentWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.docPath,
          enabled: widget.isIdEditable,
          onSubmitted: widget.isIdEditable ? (v) => setState(() {}) : null,
          decoration: InputDecoration(
            icon: Icon(Icons.location_pin),
            hintText:
                'Document Path. CollectionId/DocumentId/CollectionId/DocumentId/...',
          ),
        ),
        StreamBuilder(
            stream: db.doc(widget.docPath.text).snapshots(),
            builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return Center(child: CircularProgressIndicator());
              if (snapshot.data?.data() != null)
                widget.textDocBody.text =
                    JsonEncoder.withIndent("  ").convert(snapshot.data?.data());
              return Expanded(
                child: SingleChildScrollView(
                  child: TextField(
                    controller: widget.textDocBody,
                    decoration: InputDecoration(
                      icon: Icon(Icons.edit),
                      hintText: 'JSON format.',
                    ),
                    maxLines: null,
                  ),
                ),
              );
            }),
      ],
    );
  }
}

AlertDialog documentEditorDialog(BuildContext context, DocumentReference dRef,
    {List<Widget> Function(BuildContext)? buttonBuilder}) {
  DocumentWidget docWidget = DocumentWidget(dRef, isIdEditable: true);
  TextButton applyButton = TextButton(
      onPressed: () => docWidget.setDocumentWithTime(context),
      child: Text("Apply"));
  TextButton closeButton =
      TextButton(onPressed: () => naviPop(context), child: Text("Close"));

  List<Widget> additionalButton =
      (buttonBuilder != null) ? buttonBuilder(context) : [];

  return AlertDialog(
    title: Row(
        children: <Widget>[Expanded(child: Text("Document"))] +
            additionalButton +
            [applyButton, closeButton]),
    insetPadding: EdgeInsets.only(top: 200.0, left: 10, right: 10, bottom: 10),
    content: Column(children: [
      Expanded(child: docWidget),
    ]),
  );
}

Future<String?> showDocumentEditorDialog(
    BuildContext context, DocumentReference dRef,
    {List<Widget> Function(BuildContext)? buttonBuilder}) {
  return showDialog<String>(
      context: context,
      builder: (context) =>
          documentEditorDialog(context, dRef, buttonBuilder: buttonBuilder));
}

Future showAlertDialog(context, Widget content) async {
  await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
              title: Text('Alert Dialog'),
              content: content,
              actions: <Widget>[
                SimpleDialogOption(
                    child: Text('Close'),
                    onPressed: () => Navigator.pop(context)),
              ]));
}

Future<T?> showConfirmDialog<T>(
        context, String msg, T Function(BuildContext) op) =>
    showDialog<T>(
        context: context,
        builder: (BuildContext context) =>
            SimpleDialog(title: Text(msg), children: [
              SimpleDialogOption(
                  child: Text('OK'),
                  onPressed: () => Navigator.pop(context, op(context))),
              SimpleDialogOption(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.pop(context)),
            ]));

naviPop<T extends Object?>(BuildContext context, [T? result]) =>
    Navigator.pop(context, result);

// some snippet
naviPush(BuildContext context, WidgetBuilder builder) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: builder,
    ),
  );
}
