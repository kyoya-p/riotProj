import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'type.freezed.dart'; // freezed等でヘルパコードを生成する必要あり

@freezed
class Person with _$Person {
  factory Person({@Default('noname') String name, int? age}) = _Person;
}

@freezed
class DiscoveryResult with _$DiscoveryResult {
  factory DiscoveryResult(Timestamp time,String ip,List<String> vbs) = _DiscoveryResult;
}
