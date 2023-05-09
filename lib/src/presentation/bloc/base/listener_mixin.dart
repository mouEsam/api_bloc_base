import 'package:flutter/foundation.dart';

import 'traffic_lights_mixin.dart';

mixin ListenerMixin<State> on TrafficLightsMixin<State> {
  bool get isListening => lastTrafficLightsValue;

  ValueListenable<bool> get isListeningNotifier => isGreen;
}
