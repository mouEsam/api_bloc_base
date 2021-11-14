import 'package:api_bloc_base/src/presentation/bloc/base/traffic_lights_mixin.dart';
import 'package:flutter/foundation.dart';

mixin VisibilityMixin<State> on TrafficLightsMixin<State> {
  final ValueNotifier<bool> _isVisible = ValueNotifier(true);

  bool get isVisible => _isVisible.value;

  get notifiers => super.notifiers..add(_isVisible);
  get trafficLights => super.trafficLights..add(_isVisible);

  void setVisible(bool visible) {
    _isVisible.value = visible;
  }
}
