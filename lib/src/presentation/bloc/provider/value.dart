import 'dart:async';

import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:flutter/foundation.dart';

Stream<Loaded<T>> _toStream<T>(
        ValueListenable<T> _listenable, bool replayValue) =>
    _listenable
        .toValueStream(replayValue: replayValue)
        .map((event) => Loaded(event));

class ValueSource<T> extends StreamView<Loaded<T>> with _ValueSource<T> {
  final ValueListenable<T> _listenable;

  ValueSource(this._listenable, [bool replayValueOnListen = true])
      : super(_toStream(_listenable, replayValueOnListen));

  factory ValueSource.value(T value, [bool replayValueOnListen = true]) {
    return ValueNotifierSource(ValueNotifier(value), replayValueOnListen);
  }
}

class ValueNotifierSource<T> extends ValueSource<T> with _ValueEditor<T> {
  final ValueNotifier<T> _listenable;

  ValueNotifierSource(this._listenable, [bool replayValueOnListen = true])
      : super(_listenable, replayValueOnListen);

  factory ValueNotifierSource.value(T value,
      [bool replayValueOnListen = true]) {
    return ValueNotifierSource(ValueNotifier(value), replayValueOnListen);
  }
}

mixin _ValueSource<T> {
  ValueListenable<T> get _listenable;
  T get value => _listenable.value;
}

mixin _ValueEditor<T> {
  ValueNotifier<T> get _listenable;
  set value(T value) {
    _listenable.value = value;
  }
}
