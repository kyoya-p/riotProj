import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:cloud_firestore/cloud_firestore.dart';

part 'type.freezed.dart'; // freezed等でヘルパコードを生成する必要あり
part 'type.g.dart';



@freezed
class Person with _$Person {
  @JsonSerializable(explicitToJson: true)
  factory Person({@Default('noname') String name, int? age}) = _Person;
}

@freezed
class Discres with _$Discres {
  factory Discres( @TimestampConverter() Timestamp time, String ip, List<String> vbs) = _Discres;
  factory Discres.fromJson(Map<String, Object?> json) =>      _$DiscresFromJson(json);
}

class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp timestamp) {
    return timestamp.toDate();
  }

  @override
  Timestamp toJson(DateTime date) => Timestamp.fromDate(date);
}

// @freezed
// abstract class Profile with _$Profile {
//   factory Profile(
//       {String? name,
//       @TimestampConverter() DateTime? birthDate // ←@TimestampConverter()をつける
//       }) = _Profile;

//   factory Profile.fromJson(Map<String, dynamic> json) =>
//       _$ProfileFromJson(json);
// }
