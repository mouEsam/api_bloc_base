import 'dart:core' as core show Enum;
import 'dart:core' hide Enum;

import 'package:api_bloc_base/src/domain/entity/entity.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';

abstract class Enum<E extends core.Enum> extends Entity {
  late final String _name;
  late final E? _value;

  String get name => _name;

  E? get value => _value;

  E get requireValue => _value as E;

  bool get exists => _value != null;

  Enum(E value)
      : _value = value,
        _name = value.name;

  Enum.fromString(String value, List<E> values, bool allowUnknown) {
    _init(values, value, allowUnknown);
  }

  Enum.fromJson(String value, List<E> values, bool allowUnknown) {
    _init(values, value, allowUnknown);
  }

  void _init(List<E> values, String value, bool? allowUnknown) {
    final existingValue = EnumToString.fromString<E>(values, value);
    if (existingValue != null) {
      _value = existingValue;
      _name = value;
    } else if (allowUnknown == true) {
      _value = null;
      _name = value;
    } else {
      throw FlutterError("Unknown ${E.runtimeType} value: $value");
    }
  }

  @override
  get props => [_name, _value];

  String toJson() => _name;
}

mixin ClosedEnumMixin<E extends core.Enum> on Enum<E> {
  E get value => super.requireValue;
}

extension EnumName on core.Enum {
  String get name => EnumToString.convertToString(this);

  String get key => name;

  String get shortName => '${key}_SHORT';
}

extension EnumUtils<E extends core.Enum> on Enum<E>? {
  bool equals(E value) => this?.value == value;
}
