import 'package:cloud_firestore/cloud_firestore.dart';

class Application {
  Application(this.raw);
  late Map<String, dynamic> raw;
  String? get ag => raw["ag"] as String?;
  set ag(String? s) => raw["ag"] = s;
}

// d/*/reports/*
class Log {
  Log(this.raw);
  dynamic raw;
  Timestamp get time => raw["time"] as Timestamp;
  Iterable<VmLog> get vmlogs =>
      VmLog.fromList(raw["vmlogs"] as Iterable<dynamic>);
  Iterable<SnmpLog> get snmpLogs =>
      SnmpLog.fromList(raw["snmpLogs"] as Iterable<dynamic>);
}

class VmLog {
  VmLog(this.raw) {
    final log = raw["log"] as String;
    vVmstatLog =
        log.trim().split(RegExp("\\s+")).map((e) => int.parse(e)).toList();
  }
  dynamic raw;
  static Iterable<VmLog> fromList(Iterable<dynamic> v) => v.expand((e) {
        try {
          return <VmLog>[VmLog(e)];
        } catch (ex, _) {
          return <VmLog>[];
        }
      });

  Timestamp get time => raw["time"] as Timestamp;
  String get log => raw["log"] as String;

  late List<int> vVmstatLog;
  int vs(int i) {
    try {
      return vVmstatLog[i];
    } catch (ex) {
      return 0;
    }
  }

  int get procWaitRun => vs(0);
  int get procIoBlocked => vs(1);
  int get memSwap => vs(2);
  int get memFree => vs(3);
  int get memBuff => vs(4);
  int get memCache => vs(5);
  int get swapIn => vs(6);
  int get swapOut => vs(7);
  int get ioIn => vs(8);
  int get ioOut => vs(9);
  int get sysIntr => vs(10);
  int get sysCtxSw => vs(11);
  int get cpuUser => vs(12);
  int get cpuSys => vs(13);
  int get cpuIdle => vs(14);
  int get cpuWait => vs(15);
  int get cpuStolen => vs(16);
}

class SnmpLog {
  SnmpLog(this.raw);
  dynamic raw;

  static Iterable<SnmpLog> fromList(Iterable<dynamic> v) => v.expand((e) {
        try {
          return <SnmpLog>[SnmpLog(e)];
        } catch (ex, _) {
          return <SnmpLog>[];
        }
      });

  Timestamp get time => raw["time"] as Timestamp;
  int get scanCount => raw["scanCount"] as int;
  int get detectCount => raw["detectCount"] as int;
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
  String get id => raw["id"] as String? ?? "undefined";
  String get ip => raw["ip"] as String;
  Timestamp get time => raw["time"] as Timestamp;
  List<String> get vbs =>
      (raw["vbs"] as List<dynamic>).map((e) => e as String).toList();

  Map<String, String> get vbm => Map<String, String>.from(raw["vbm"]);
}
