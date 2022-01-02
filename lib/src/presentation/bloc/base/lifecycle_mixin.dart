import 'package:api_bloc_base/src/presentation/bloc/provider/lifecycle_observer.dart';
import 'package:flutter/foundation.dart';

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

  @override
  void onResume() {
    isAppGreen.value = true;
    print(trafficLights.map((e) => e.value).toList());
    onAppState(true);
  }

  @override
  void onPause() {
    isAppGreen.value = false;
    onAppState(false);
  }

  @override
  void onDetach() {}

  @override
  void onInactive() {}

  void onAppState(bool isActive) {}

  @override
  Future<void> close() {
    appLifecycleObserver?.removeListener(this);
    return super.close();
  }
}
