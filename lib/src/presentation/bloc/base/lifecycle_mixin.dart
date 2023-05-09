import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/provider/lifecycle_observer.dart';
import 'package:flutter/foundation.dart';
import 'package:listenable_stream/listenable_stream.dart';

import 'traffic_lights_mixin.dart';

mixin LifecycleMixin<State> on TrafficLightsMixin<State>
    implements LifecycleAware {
  LifecycleObserver? get appLifecycleObserver;

  final ValueNotifier<bool> _isAppGreen = ValueNotifier(true);
  ValueListenable<bool> get isAppGreen => _isAppGreen;

  @override
  List<ValueListenable<bool>> get trafficLights => super.trafficLights..add(isAppGreen);

  bool _init = false;
  @override
  void init() {
    if (_init) return;
    _init = true;
    appLifecycleObserver?.addListener(this);
    super.init();
  }

  Future<R> whenAppActive<R extends Object?>({
    FutureOr<R> Function(bool isActive)? producer,
    bool isActive = true,
  }) {
    producer ??= (_) => Future.value(null);
    return isAppGreen
        .toValueStream(replayValue: true)
        .firstWhere((event) => event == isActive)
        .then((value) => producer!(value));
  }

  @override
  void onResume() {
    _onChange(true);
  }

  @override
  void onActive() {
    _onChange(true);
  }

  @override
  void onPause() {
    _onChange(false);
  }

  void _onChange(bool isActive) {
    onAppState(isActive);
    _isAppGreen.value = isActive;
    onAppStateChanged(isActive);
  }

  @override
  void onDetach() {}

  @override
  void onInactive() {}

  @mustCallSuper
  void onAppState(bool isActive) {}

  @mustCallSuper
  void onAppStateChanged(bool isActive) {}

  @override
  Future<void> close() {
    appLifecycleObserver?.removeListener(this);
    return super.close();
  }
}
