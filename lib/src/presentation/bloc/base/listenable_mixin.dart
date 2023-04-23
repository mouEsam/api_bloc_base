import 'package:flutter/widgets.dart';

import 'listener_mixin.dart';
import 'traffic_lights_mixin.dart';

mixin BlocListenerStateMixin<T extends StatefulWidget> on State<T> {
  ListenableMixin get listenable;

  @override
  void initState() {
    listenable.addStateListener(this);
    super.initState();
  }

  @override
  void dispose() {
    listenable.removeStateListener(this);
    super.dispose();
  }
}

mixin ListenableMixin<BlocState> on TrafficLightsMixin<BlocState> {
  bool get canRunWithoutListeners;

  late final ValueNotifier<bool> _canRunWithoutListeners =
      ValueNotifier(canRunWithoutListeners);
  late final ValueNotifier<bool> _isListenedTo =
      ValueNotifier(_canRunWithoutListeners.value);

  final List<ListenerMixin> _listeners = [];
  final List<ListenableMixin> _listenableListeners = [];
  final List<TrafficLightsMixin> _generalListeners = [];
  final List<State> _widgetListeners = [];

  @override
  get notifiers => super.notifiers..add(_isListenedTo);

  @override
  get trafficLights => super.trafficLights..add(_isListenedTo);

  void addListener(TrafficLightsMixin listener) {
    if (listener is ListenableMixin) {
      _listenableListeners.add(listener);
      listener._canRunWithoutListeners.addListener(_changed);
    } else if (listener is ListenerMixin) {
      listener.isListeningNotifier.addListener(_changed);
      _listeners.add(listener);
    } else {
      _generalListeners.add(listener);
    }
    _changed();
  }

  void addStateListener(State listener) {
    _widgetListeners.add(listener);
    _changed();
  }

  void removeListener(TrafficLightsMixin listener) {
    if (listener is ListenableMixin) {
      _listenableListeners.remove(listener);
      listener._canRunWithoutListeners.removeListener(_changed);
    } else if (listener is ListenerMixin) {
      listener.isListeningNotifier.removeListener(_changed);
      _listeners.remove(listener);
    } else {
      _generalListeners.remove(listener);
    }
    _changed();
  }

  void removeStateListener(State listener) {
    _widgetListeners.remove(listener);
    _changed();
  }

  void _changed() {
    _isListenedTo.value = _getIsListenedTo();
  }

  bool _getIsListenedTo() {
    if (_canRunWithoutListeners.value) {
      return true;
    }
    for (final l in _generalListeners) {
      if (l.lastTrafficLightsValue) {
        return true;
      }
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
    return _widgetListeners.isNotEmpty;
  }

  @override
  Future<void> close() {
    _listeners.clear();
    _listenableListeners.clear();
    _generalListeners.clear();
    _widgetListeners.clear();
    return super.close();
  }
}
