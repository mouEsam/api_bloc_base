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
  final bool _owned;
  bool _isClosed = false;

  ValueSource(
    this._listenable, {
    bool replayValueOnListen = true,
    bool owned = false,
  })  : _owned = owned,
        super(_toStream(_listenable, replayValueOnListen));

  factory ValueSource.value(T value, {bool replayValueOnListen}) =
      ValueNotifierSource.value;

  @override
  bool get isClosed => _isClosed;

  @override
  void close() {
    _isClosed = true;
    if (_owned && _listenable is ValueNotifier) {
      (_listenable as ValueNotifier).dispose();
    }
  }
}

class ValueNotifierSource<T> extends ValueSource<T> with _ValueEditor<T> {
  final ValueNotifier<T> _listenable;

  ValueNotifierSource(
    this._listenable, {
    bool replayValueOnListen = true,
    bool owned = false,
  }) : super(
          _listenable,
          replayValueOnListen: replayValueOnListen,
          owned: owned,
        );

  factory ValueNotifierSource.value(T value,
      {bool replayValueOnListen = true}) {
    return ValueNotifierSource(
      ValueNotifier(value),
      replayValueOnListen: replayValueOnListen,
      owned: true,
    );
  }
}

mixin _ValueSource<T> implements Closable {
  ValueListenable<T> get _listenable;
  T get value => _listenable.value;
  void close();
}

mixin _ValueEditor<T> {
  ValueNotifier<T> get _listenable;
  set value(T value) {
    _listenable.value = value;
  }
}
