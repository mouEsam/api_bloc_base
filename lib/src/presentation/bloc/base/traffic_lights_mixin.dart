import 'package:api_bloc_base/src/presentation/bloc/base/base_bloc.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/initializable.dart';
import 'package:flutter/foundation.dart';

mixin TrafficLightsMixin<State> on BaseCubit<State>, Initializable {
  final ValueNotifier<bool> isGreen = ValueNotifier(true);

  late final Listenable _singleTrafficLights;
  bool get lastTrafficLightsValue => isGreen.value;

  List<ValueNotifier<bool>> get trafficLights => [];

  @override
  get notifiers => super.notifiers..addAll([...trafficLights, isGreen]);
  bool get trafficLightsValue =>
      trafficLights.every((element) => element.value);

  void trafficLightsChanged(bool green);

  @override
  void init() {
    setupTrafficLights();
    super.init();
  }

  bool _init = false;
  void setupTrafficLights() {
    if (_init) return;
    _init = true;
    isGreen.value = trafficLightsValue;
    isGreen.addListener(_alert);
    _singleTrafficLights = Listenable.merge(trafficLights);
    _singleTrafficLights.addListener(_changed);
  }

  void _alert() {
    trafficLightsChanged(isGreen.value);
  }

  void _changed() {
    isGreen.value = trafficLightsValue;
  }

  @override
  Future<void> close() {
    isGreen.removeListener(_alert);
    _singleTrafficLights.removeListener(_changed);
    return super.close();
  }
}
