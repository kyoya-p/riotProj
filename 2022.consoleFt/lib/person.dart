import 'package:freezed_annotation/freezed_annotation.dart';
part 'person.freezed.dart'; // freezed等でヘルパコードを生成する必要あり

@freezed
class Person with _$Person {
  factory Person({@Default('noname') String name, int? age}) = _Person;
}
main() {
  final user = Person(name: "shokkaa");
  print('${user.name} / ${user.toString()}');
}
