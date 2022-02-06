import 'dart:async';

import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:flutter/foundation.dart';

Stream<ProviderLoaded<T>> _toStream<T>(
        ValueListenable<T> _listenable, bool replayValue) =>
    _listenable
        .toValueStream(replayValue: replayValue)
        .map((event) => ProviderLoaded(event));

class ValueProvider<T> extends StreamView<ProviderLoaded<T>> with _ValueProvider<T> {
  final ValueListenable<T> _listenable;

  ValueProvider(this._listenable, [bool replayValueOnListen = true])
      : super(_toStream(_listenable, replayValueOnListen));

  factory ValueProvider.value(T value, [bool replayValueOnListen = true]) {
    return ValueNotifierProvider(ValueNotifier(value), replayValueOnListen);
  }
}

class ValueNotifierProvider<T> extends ValueProvider<T> with _ValueEditor<T> {
  final ValueNotifier<T> _listenable;

  ValueNotifierProvider(this._listenable, [bool replayValueOnListen = true])
      : super(_listenable, replayValueOnListen);

  factory ValueNotifierProvider.value(T value,
      [bool replayValueOnListen = true]) {
    return ValueNotifierProvider(ValueNotifier(value), replayValueOnListen);
  }
}

mixin _ValueProvider<T> {
  ValueListenable<T> get _listenable;
  T get value => _listenable.value;
}

mixin _ValueEditor<T> {
  ValueNotifier<T> get _listenable;
  set value(T value) {
    _listenable.value = value;
  }
}
