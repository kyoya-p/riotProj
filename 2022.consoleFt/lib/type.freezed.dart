// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'type.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$Person {
  String get name => throw _privateConstructorUsedError;
  int? get age => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $PersonCopyWith<Person> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PersonCopyWith<$Res> {
  factory $PersonCopyWith(Person value, $Res Function(Person) then) =
      _$PersonCopyWithImpl<$Res>;
  $Res call({String name, int? age});
}

/// @nodoc
class _$PersonCopyWithImpl<$Res> implements $PersonCopyWith<$Res> {
  _$PersonCopyWithImpl(this._value, this._then);

  final Person _value;
  // ignore: unused_field
  final $Res Function(Person) _then;

  @override
  $Res call({
    Object? name = freezed,
    Object? age = freezed,
  }) {
    return _then(_value.copyWith(
      name: name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      age: age == freezed
          ? _value.age
          : age // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
abstract class _$$_PersonCopyWith<$Res> implements $PersonCopyWith<$Res> {
  factory _$$_PersonCopyWith(_$_Person value, $Res Function(_$_Person) then) =
      __$$_PersonCopyWithImpl<$Res>;
  @override
  $Res call({String name, int? age});
}

/// @nodoc
class __$$_PersonCopyWithImpl<$Res> extends _$PersonCopyWithImpl<$Res>
    implements _$$_PersonCopyWith<$Res> {
  __$$_PersonCopyWithImpl(_$_Person _value, $Res Function(_$_Person) _then)
      : super(_value, (v) => _then(v as _$_Person));

  @override
  _$_Person get _value => super._value as _$_Person;

  @override
  $Res call({
    Object? name = freezed,
    Object? age = freezed,
  }) {
    return _then(_$_Person(
      name: name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      age: age == freezed
          ? _value.age
          : age // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$_Person implements _Person {
  _$_Person({this.name = 'noname', this.age});

  @override
  @JsonKey()
  final String name;
  @override
  final int? age;

  @override
  String toString() {
    return 'Person(name: $name, age: $age)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_Person &&
            const DeepCollectionEquality().equals(other.name, name) &&
            const DeepCollectionEquality().equals(other.age, age));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(name),
      const DeepCollectionEquality().hash(age));

  @JsonKey(ignore: true)
  @override
  _$$_PersonCopyWith<_$_Person> get copyWith =>
      __$$_PersonCopyWithImpl<_$_Person>(this, _$identity);
}

abstract class _Person implements Person {
  factory _Person({final String name, final int? age}) = _$_Person;

  @override
  String get name => throw _privateConstructorUsedError;
  @override
  int? get age => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$$_PersonCopyWith<_$_Person> get copyWith =>
      throw _privateConstructorUsedError;
}

Discres _$DiscresFromJson(Map<String, dynamic> json) {
  return _Discres.fromJson(json);
}

/// @nodoc
mixin _$Discres {
  Timestamp get time => throw _privateConstructorUsedError;
  String get ip => throw _privateConstructorUsedError;
  List<String> get vbs => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DiscresCopyWith<Discres> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiscresCopyWith<$Res> {
  factory $DiscresCopyWith(Discres value, $Res Function(Discres) then) =
      _$DiscresCopyWithImpl<$Res>;
  $Res call({Timestamp time, String ip, List<String> vbs});
}

/// @nodoc
class _$DiscresCopyWithImpl<$Res> implements $DiscresCopyWith<$Res> {
  _$DiscresCopyWithImpl(this._value, this._then);

  final Discres _value;
  // ignore: unused_field
  final $Res Function(Discres) _then;

  @override
  $Res call({
    Object? time = freezed,
    Object? ip = freezed,
    Object? vbs = freezed,
  }) {
    return _then(_value.copyWith(
      time: time == freezed
          ? _value.time
          : time // ignore: cast_nullable_to_non_nullable
              as Timestamp,
      ip: ip == freezed
          ? _value.ip
          : ip // ignore: cast_nullable_to_non_nullable
              as String,
      vbs: vbs == freezed
          ? _value.vbs
          : vbs // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
abstract class _$$_DiscresCopyWith<$Res> implements $DiscresCopyWith<$Res> {
  factory _$$_DiscresCopyWith(
          _$_Discres value, $Res Function(_$_Discres) then) =
      __$$_DiscresCopyWithImpl<$Res>;
  @override
  $Res call({Timestamp time, String ip, List<String> vbs});
}

/// @nodoc
class __$$_DiscresCopyWithImpl<$Res> extends _$DiscresCopyWithImpl<$Res>
    implements _$$_DiscresCopyWith<$Res> {
  __$$_DiscresCopyWithImpl(_$_Discres _value, $Res Function(_$_Discres) _then)
      : super(_value, (v) => _then(v as _$_Discres));

  @override
  _$_Discres get _value => super._value as _$_Discres;

  @override
  $Res call({
    Object? time = freezed,
    Object? ip = freezed,
    Object? vbs = freezed,
  }) {
    return _then(_$_Discres(
      time == freezed
          ? _value.time
          : time // ignore: cast_nullable_to_non_nullable
              as Timestamp,
      ip == freezed
          ? _value.ip
          : ip // ignore: cast_nullable_to_non_nullable
              as String,
      vbs == freezed
          ? _value._vbs
          : vbs // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_Discres implements _Discres {
  _$_Discres(this.time, this.ip, final List<String> vbs) : _vbs = vbs;

  factory _$_Discres.fromJson(Map<String, dynamic> json) =>
      _$$_DiscresFromJson(json);

  @override
  final Timestamp time;
  @override
  final String ip;
  final List<String> _vbs;
  @override
  List<String> get vbs {
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_vbs);
  }

  @override
  String toString() {
    return 'Discres(time: $time, ip: $ip, vbs: $vbs)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_Discres &&
            const DeepCollectionEquality().equals(other.time, time) &&
            const DeepCollectionEquality().equals(other.ip, ip) &&
            const DeepCollectionEquality().equals(other._vbs, _vbs));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(time),
      const DeepCollectionEquality().hash(ip),
      const DeepCollectionEquality().hash(_vbs));

  @JsonKey(ignore: true)
  @override
  _$$_DiscresCopyWith<_$_Discres> get copyWith =>
      __$$_DiscresCopyWithImpl<_$_Discres>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_DiscresToJson(this);
  }
}

abstract class _Discres implements Discres {
  factory _Discres(
          final Timestamp time, final String ip, final List<String> vbs) =
      _$_Discres;

  factory _Discres.fromJson(Map<String, dynamic> json) = _$_Discres.fromJson;

  @override
  Timestamp get time => throw _privateConstructorUsedError;
  @override
  String get ip => throw _privateConstructorUsedError;
  @override
  List<String> get vbs => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$$_DiscresCopyWith<_$_Discres> get copyWith =>
      throw _privateConstructorUsedError;
}
