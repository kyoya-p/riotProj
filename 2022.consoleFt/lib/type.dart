import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:cloud_firestore/cloud_firestore.dart';

class Application {
  Application(this.map);

  late Map<String, dynamic> map;
  String? get ag => map["ag"] as String?;
  set ag(String? s) => map["ag"] = s;
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

class DiscoveryRes {
  DiscoveryRes(this.map);
  Map<String, dynamic> map;
  get ip => map["ip"] as String;
  get time => map["time"] as Timestamp;
  get vbs => (map["vbs"] as List<dynamic>).map((e) => e as String).toList();
  get id => map["id"] as String? ?? "undefined";
}
