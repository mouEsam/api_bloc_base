import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/provider/lifecycle_observer.dart';
import 'package:flutter/foundation.dart';
import 'package:listenable_stream/listenable_stream.dart';

import 'traffic_lights_mixin.dart';

mixin LifecycleMixin<State> on TrafficLightsMixin<State>
    implements LifecycleAware {
  LifecycleObserver? get appLifecycleObserver;

  final ValueNotifier<bool> isAppGreen = ValueNotifier(true);

  get trafficLights => super.trafficLights..add(isAppGreen);

  init() {
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
  void onPause() {
    _onChange(false);
  }

  void _onChange(bool isActive) {
    onAppState(isActive);
    isAppGreen.value = isActive;
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
  close() {
    appLifecycleObserver?.removeListener(this);
    return super.close();
  }
}
