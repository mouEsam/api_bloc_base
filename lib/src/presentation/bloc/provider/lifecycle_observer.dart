import 'package:flutter/material.dart';

abstract class LifecycleAware {
  void onResume();

  void onPause();

  void onActive();

  void onDetach();

  void onInactive();
}

mixin LifecycleObserver on WidgetsBindingObserver {
  AppLifecycleState _lastAppState = AppLifecycleState.resumed;
  final Set<LifecycleAware> _listeners = {};

  void addListener(LifecycleAware listener) {
    _listeners.add(listener);
  }

  void removeListener(LifecycleAware listener) {
    _listeners.remove(listener);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _listeners
          .whereType<LifecycleAware>()
          .forEach((element) => element.onPause());
    } else if (state == AppLifecycleState.resumed) {
      if (_lastAppState != AppLifecycleState.resumed) {
        _listeners
            .whereType<LifecycleAware>()
            .forEach((element) => element.onResume());
      } else {
        _listeners
            .whereType<LifecycleAware>()
            .forEach((element) => element.onActive());
      }
    } else if (state == AppLifecycleState.inactive) {
      _listeners
          .whereType<LifecycleAware>()
          .forEach((element) => element.onInactive());
    } else if (state == AppLifecycleState.detached) {
      _listeners
          .whereType<LifecycleAware>()
          .forEach((element) => element.onDetach());
    }
    _lastAppState = state;
  }
}
