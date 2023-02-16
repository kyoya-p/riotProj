import 'package:flutter/material.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';

import 'documentPage.dart';

class MfpViewerAppWidget extends StatelessWidget {
  MfpViewerAppWidget(this.devId);

  final String devId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("XXX")),
      body: DocumentWidget(//TODO
          FirebaseFirestore.instance.collection("device").doc(devId)),
    );
  }
}
