import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'listener_mixin.dart';
import 'traffic_lights_mixin.dart';

mixin ListenableMixin<State> on TrafficLightsMixin<State> {
  bool get canRunWithoutListeners;

  late final ValueNotifier<bool> _canRunWithoutListeners =
      ValueNotifier(canRunWithoutListeners);
  late final ValueNotifier<bool> _isListenedTo =
      ValueNotifier(_canRunWithoutListeners.value);

  final List<ListenerMixin> _listeners = [];
  final List<ListenableMixin> _listenableListeners = [];

  @override
  get notifiers => super.notifiers..add(_isListenedTo);
  @override
  get trafficLights => super.trafficLights..add(_isListenedTo);

  void addListener(ListenerMixin listener) {
    if (listener is ListenableMixin) {
      final listenable = listener as ListenableMixin;
      _listenableListeners.add(listenable);
      listenable._canRunWithoutListeners.addListener(_changed);
    } else {
      _listeners.add(listener);
    }
    listener.isListeningNotifier.addListener(_changed);
    _changed();
  }

  void removeListener(ListenerMixin listener) {
    if (listener is ListenableMixin) {
      final listenable = listener as ListenableMixin;
      _listenableListeners.remove(listenable);
      listenable._canRunWithoutListeners.removeListener(_changed);
    } else {
      _listeners.remove(listener);
    }
    listener.isListeningNotifier.removeListener(_changed);
    _changed();
  }

  void _changed() {
    _isListenedTo.value = _getIsListenedTo();
  }

  bool _getIsListenedTo() {
    if (_canRunWithoutListeners.value) {
      return true;
    }
    for (final l in _listeners) {
      if (l.isListeningNotifier.value) {
        return true;
      }
    }
    for (final l in _listenableListeners) {
      if (l._canRunWithoutListeners.value ||
          (l as ListenerMixin).isListeningNotifier.value) {
        return true;
      }
    }
    return false;
  }
}
