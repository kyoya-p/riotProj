import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:console_ft/vmstatChart.dart';
// import 'package:freezed_annotation/freezed_annotation.dart';
// import 'package:firebase_core/firebase_core.dart' show Firebase;
// import 'package:cloud_firestore/cloud_firestore.dart';

class Application {
  Application(this.raw);
  late Map<String, dynamic> raw;
  String? get ag => raw["ag"] as String?;
  set ag(String? s) => raw["ag"] = s;
}

class Device {
  Device(this.raw);
  Map<String, dynamic> raw;
}

class Log {
  Log(this.raw);
  dynamic raw;
  Timestamp get time => raw["time"] as Timestamp;
  Iterable<Vmlog> get vmlogs => Vmlog.fromList(raw["vmlogs"] as Iterable);
}

class Vmlog {
  Vmlog(this.raw);
  dynamic raw;
  static Iterable<Vmlog> fromList(Iterable v) => v.map((e) => Vmlog(e));
  Timestamp get time => raw["time"] as Timestamp;
  String get log => raw["log"] as String;
}

class SnmpScanner {
  SnmpScanner(this.map);
  Map<String, dynamic> map;
  String? get id => map["id"] as String?;
  String? get ipSpec => map["ipSpec"] as String?;
  set ipSpec(String? s) => map["ipSpec"] = s;
  int? get interval => map["interval"] as int?;
  set interval(int? i) => map["interval"] = i;
}

class SnmpMetrics {
  SnmpMetrics(this.raw);
  dynamic raw;
  DateTime? get time => raw["time"] as DateTime?;
  set time(DateTime? v) => raw["time"] = v;
}

class DiscoveryRes {
  DiscoveryRes(this.raw);
  dynamic raw;
  String get ip => raw["ip"] as String;
  Timestamp get time => raw["time"] as Timestamp;
  List<String> get vbs =>
      (raw["vbs"] as List<dynamic>).map((e) => e as String).toList();
  String get id => raw["id"] as String? ?? "undefined";
}
