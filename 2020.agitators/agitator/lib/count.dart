// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_auth/firebase_auth.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_core/firebase_core.dart';

/*
 ドキュメント数をカウントし、サマリを保存する
 logCount/segment=
 {
   since: Timestamp
   period: int //in sec
   count: int
 }
*/

void countTest() async {
  print("get last log..");
  Firebase.initializeApp();
  await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: "kyoya.p4@gmail.com", password: "kyoyap4");

  //User user = FirebaseAuth.instance.currentUser;//TODO
  //print(user); //TODO
  FirebaseFirestore db = FirebaseFirestore.instance;
  //Query targetItems = db.collectionGroup("device/KK1/logs").orderBy("time").limit(1000);

  int lastTotalCount = 0;
  int lastTime = 0;

  CollectionReference summaryCollection = db.collection("tmpCount");
  // 最後のログから継続する場合
  QuerySnapshot lastSummary = await summaryCollection
      .orderBy("endTime", descending: true)
      .limit(1)
      .get();
  if (lastSummary.size != 0) {
    lastTime = lastSummary.docs[0]["endTime"];
    lastTotalCount = lastSummary.docs[0]["totalCount"];
  }
  print("lastTime=$lastTime");
  print("lastTotalCount=$lastTotalCount");

  Query targetItems = db
      .collectionGroup("logs")
      .orderBy("time")
      .where("time", isGreaterThan: lastTime)
      .limit(100);

  print("start counting..");
  int res = await makeCountSummary(
    targetItems,
    summaryCollection,
    "time",
    DateTime.now().toUtc().millisecondsSinceEpoch,
    1000,
    lastTotalCount: lastTotalCount,
    lastTime: lastTime,
  );
  print("totalCount= $res");
}

Future<int> makeCountSummary(
    Query targetItems,
    CollectionReference summaryCollection,
    String timeField,
    int time,
    int resolutionInSecond,
    {int lastTotalCount = 0,
    int lastTime = 0}) async {
  int totalCount = lastTotalCount;

  await listItems(targetItems, timeField, time, (e) {
    int t = e[timeField] ~/ resolutionInSecond * resolutionInSecond;
    if (t != lastTime) {
      CountSegment seg = CountSegment(lastTime, t - lastTime,
          totalCount: totalCount, periodCount: totalCount - lastTotalCount);
      lastTotalCount = totalCount;
      print("${DateTime.fromMillisecondsSinceEpoch(seg.startTime)} $seg");
      summaryCollection.doc("${seg.startTime}:${seg.period}").set(seg.toMap());
      lastTime = t;
    }
    totalCount = totalCount + 1;
  });
  if (time ~/ resolutionInSecond != lastTime) {
    CountSegment seg = CountSegment(
        lastTime, (time ~/ resolutionInSecond * resolutionInSecond) - lastTime,
        totalCount: totalCount, periodCount: totalCount - lastTotalCount);
    print("${DateTime.fromMillisecondsSinceEpoch(seg.startTime)} $seg");
  }
  return totalCount;
}

/*Future<int> makeCountSummary_X1(
  Query targetItems,
  CollectionReference summaryCollection,
  String timeField,
  int time,
  int minResolutionInSecond,
) async {
  List<CountSegment> currentCountSegs = List.from([], growable: true);

  listItems(targetItems, timeField, time, (e) {
    int t = e[timeField]; //TODO
    List<CountSegment> newCountSegs = makeSegments(t);

    for (int i = 0; i < newCountSegs.length; ++i) {
      if (currentCountSegs.length <= i) currentCountSegs.add(newCountSegs[i]);
      if (currentCountSegs[i].since == newCountSegs[i].since) {
        currentCountSegs[i].totalCount = currentCountSegs[i].totalCount + 1;
      } else {
        var e = currentCountSegs[i];
        print("[${e.since}~${e.period}:${e.totalCount}]");
        currentCountSegs[i] = newCountSegs[i]..totalCount = 1;
      }
    }
    String r = currentCountSegs
        .map((e) => "${e.since}~${e.period}:${e.totalCount}")
        .join(",");
    print("$t: $r");
  });

  return 0;
}

 */

listItems(
    // ignore: non_constant_identifier_names
    Query targetItems, String timeField, int time, op(DocumentSnapshot)) async {
  QuerySnapshot logs =
      await targetItems.where(timeField, isLessThan: time).get();
  for (DocumentSnapshot e in logs.docs) {
    op(e);
  }
}

List<CountSegment> makeSegments(int time /*[sec]*/) {
  List<CountSegment> list = [
    for (int period = 1; period <= time; period *= 2)
      CountSegment(time ~/ period * period, period)
  ];
  return list;
}

class CountSegment {
  CountSegment(this.startTime, this.period,
      {this.totalCount = 0, this.periodCount = 0});

  final int startTime;
  final int period;
  final int totalCount;
  final int periodCount;

  String toString() => "$startTime~$period:$totalCount(+$periodCount)";

  Map<String, dynamic> toMap() => {
        "timeStart": startTime,
        "timeEnd": startTime + period,
        "period": period,
        "totalCount": totalCount,
        "periodCount": periodCount,
        "type": "test",
      };
}
