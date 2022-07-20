import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

late final int localTimeOffset;

initializeServerClock() async {
  final refTime =
      await db.collection("tmp").add({"time": FieldValue.serverTimestamp()});
  final ssTime = await refTime.get();
  final docTime = ssTime.data();
  if (docTime == null) throw Exception("Error: initializeServerClock()");
  final svrTime = docTime["time"] as Timestamp;
  localTimeOffset =
      svrTime.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch;
}

DateTime getServerTime() => DateTime.fromMillisecondsSinceEpoch(
    DateTime.now().millisecondsSinceEpoch + localTimeOffset);
