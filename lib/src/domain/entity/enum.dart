import 'dart:core' as core show Enum;
import 'dart:core' hide Enum;

import 'package:api_bloc_base/src/domain/entity/entity.dart';
import 'package:enum_to_string/enum_to_string.dart';

abstract class Enum<E extends core.Enum> extends Entity {
  late final String _name;
  late final E? _value;

  String get name => _name;
  E? get value => _value;
  bool get exists => _value != null;

  Enum(E value)
      : _value = value,
        _name = EnumToString.convertToString(value);

  Enum.fromString(String value, List<E> values) {
    _init(values, value);
  }

  Enum.fromJson(String value, List<E> values) {
    _init(values, value);
  }

  void _init(List<dynamic> values, String value) {
    final existingValue = EnumToString.fromString(values, value);
    if (existingValue == null) {
      _value = null;
      _name = value;
    } else {
      _value = existingValue;
      _name = value;
    }
  }

  @override
  get props => [_name, _value];

  String toJson() => _name;
}
