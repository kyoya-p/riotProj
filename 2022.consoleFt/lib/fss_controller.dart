import 'dart:collection';
import 'package:console_ft/clock.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'document_editor.dart';
import 'main.dart';

// SNMP検索条件設定Widget
Widget fssControlerField(BuildContext context1, DocumentReference refDev) {
  return StreamBuilder<DocumentSnapshot>(
    stream: refDev.snapshots(),
    builder: (context, ssDev) {
      if (ssDev.data?.data() == null) return loadingIcon();
      final dev = ssDev.data?.data() as LinkedHashMap<dynamic, dynamic>;
      final refFssStorage = refDev.collection("storage").doc("data1");
      return StreamBuilder<DocumentSnapshot>(
          stream: refFssStorage.snapshots(),
          builder: (context, ssFssStorage) {
            if (ssFssStorage.data == null) return loadingIcon();
            var fssStorage = (ssFssStorage.data?.data() ?? {})
                as LinkedHashMap<dynamic, dynamic>;
            final initUrl =
                TextEditingController(text: dev["fssSpec"]["initUrl"]);
            final adr = TextEditingController(text: dev["fssSpec"]["adr"]);
            final pollItvl = TextEditingController(
                text: dev["fssSpec"]["pollInterval"].toString());
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                    controller: initUrl,
                    decoration: const InputDecoration(
                        label: Text("Initialize URL:"),
                        hintText: "Log in to the RMM site to obtain"),
                    onSubmitted: (_) {
                      dev["fssSpec"]["initUrl"] = initUrl.text;
                      refDev.set(dev);
                    }),
                TextField(
                    controller: adr,
                    decoration: const InputDecoration(
                        label: Text("Target SNMP address:"),
                        hintText: "Basically enter the IP address of the MFP"),
                    onSubmitted: (_) {
                      dev["fssSpec"]["adr"] = adr.text;
                      refDev.set(dev);
                    }),
                Row(children: [
                  Expanded(
                    child: TextField(
                        controller: pollItvl,
                        decoration: const InputDecoration(
                            label: Text("Polling Interval[ms]:"),
                            hintText: "FSS default is 3600000[ms] (60[min])."),
                        onSubmitted: (_) {
                          dev["fssSpec"]["pollInterval"] =
                              int.parse(pollItvl.text);
                          refDev.set(dev);
                        }),
                  ),
                  FilledButton(
                      child: const Text("Polling"),
                      onPressed: () => manualPolling(refDev)),
                  FilledButton(
                      child: const Text("Load Setting"),
                      onPressed: () => downloadDeviceSetting(refDev)),
                  FilledButton(
                      child: const Text("Mem Clear"),
                      onPressed: () => refFssStorage.delete()),
                  FilledButton(
                      child: const Text("Reboot"),
                      onPressed: () {
                        dev["time"] = getServerTime().millisecondsSinceEpoch;
                        refDev.set(dev);
                      })
                ]),
                InkWell(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Model Name: ${fssStorage["modelName"]}",
                              maxLines: 1),
                          Text("Serial Number: ${fssStorage["serialNumber"]}",
                              maxLines: 1),
                          Text("Polling URL: ${fssStorage["pollUrl"]}",
                              maxLines: 1),
                          Text("Alert URL: ${fssStorage["alertUrl"]}",
                              maxLines: 1),
                          Text("Notify URL: ${fssStorage["notifyUrl"]}",
                              maxLines: 1)
                        ]),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => DocumentPage(refFssStorage))))
              ],
            );
          });
    },
  );
}

manualPolling(DocumentReference refDev) {
  final refMachine = refDev.collection("ctrl").doc("machine");
  refMachine.set({"manualPolling": true});
}

downloadDeviceSetting(DocumentReference refDev) {
  final refMachine = refDev.collection("ctrl").doc("machine");
  refMachine.set({"downloadDeviceSetting": true});
}
