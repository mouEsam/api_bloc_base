import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/base_bloc.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/initializable.dart';
import 'package:flutter/foundation.dart';
import 'package:listenable_stream/listenable_stream.dart';

mixin TrafficLightsMixin<State> on BaseCubit<State>, Initializable {

  final ValueNotifier<bool> _isGreen = ValueNotifier(true);
  ValueListenable<bool> get isGreen => _isGreen;

  late final Listenable _singleTrafficLights;

  bool get lastTrafficLightsValue => isGreen.value;

  List<ValueListenable<bool>> get trafficLights => [];

  @override
  Set<Listenable> get notifiers => super.notifiers..addAll([...trafficLights, isGreen]);

  bool get _trafficLightsValue {
    return trafficLights.every((element) => element.value);
  }

  void trafficLightsChanged(bool green) {}

  bool _init = false;
  @override
  void init() {
    if (_init) return;
    _init = true;
    _setupTrafficLights();
    super.init();
  }

  void _setupTrafficLights() {
    _isGreen.value = _trafficLightsValue;
    _isGreen.addListener(_alert);
    _singleTrafficLights = Listenable.merge(trafficLights);
    _singleTrafficLights.addListener(_changed);
  }

  void _alert() {
    trafficLightsChanged(_isGreen.value);
  }

  void _changed() {
    print("CHANGED @ ${_trafficLightsValue}");
    _isGreen.value = _trafficLightsValue;
  }

  Future<R> whenActive<R extends Object?>({
    FutureOr<R> Function(bool isActive)? producer,
    bool isActive = true,
  }) {
    producer ??= (_) => Future.value(null);
    return isGreen
        .toValueStream(replayValue: true)
        .firstWhere((event) => event == isActive)
        .then((value) => producer!(value));
  }

  @override
  Future<void> close() {
    print("ASDASD Removing ${this}");
    isGreen.removeListener(_alert);
    _singleTrafficLights.removeListener(_changed);
    return super.close();
  }
}
