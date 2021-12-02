import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/listenable_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/stateful_bloc.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/traffic_lights_mixin.dart';
import 'package:api_bloc_base/src/utils/box.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import 'independence_mixin.dart';
import 'listener_mixin.dart';
import 'state.dart';

export 'state.dart';

mixin ListenableDependenceMixin<InputParameter, Input, Output, State>
    on
        StatefulBloc<Output, State>,
        TrafficLightsMixin<State>,
        IndependenceMixin<Input, Output, State>,
        ListenerMixin<State> {
  Box<InputParameter> _inputParameter = Box(null);

  InputParameter get inputParameter => _inputParameter.data;
  set inputParameter(InputParameter? inputParameter) =>
      _inputParameter.data = inputParameter;

  final ValueNotifier<bool> listeningToListenables = ValueNotifier(true);

  late final List<ListenableMixin<BlocState>> listenableSources;
  late final List<Stream<BlocState>> listenableStreams;

  late final StreamSubscription _streamSourceSubscription;

  @override
  get trafficLights => super.trafficLights..addAll([listeningToListenables]);
  @override
  get subscriptions => super.subscriptions..addAll([_streamSourceSubscription]);

  void pauseListenables() {
    listeningToListenables.value = false;
  }

  void resumeListenables() {
    listeningToListenables.value = true;
  }

  @mustCallSuper
  void trafficLightsChanged(bool green) {
    if (green) {
      _streamSourceSubscription.resume();
    } else {
      _streamSourceSubscription.pause();
    }
    super.trafficLightsChanged(green);
  }

  @override
  void init() {
    setupListenablesDependence();
    super.init();
  }

  bool _init = false;
  void setupListenablesDependence() {
    if (_init) return;
    _init = true;
    listenableSources.forEach((element) => element.addListener(this));
    final List<Stream<BlocState>> newSources = [
      ...listenableStreams,
      ...listenableSources.map((e) => e.stream)
    ];
    _streamSourceSubscription =
        CombineLatestStream<BlocState, List<BlocState>>(newSources, (a) => a)
            .map((event) {
      Error? errorState =
          event.firstWhereOrNull((element) => element is Error) as Error?;
      if (errorState != null) {
        return Error(errorState.response);
      } else if (event.any((element) => element is Loading)) {
        return Loading();
      } else {
        final result =
            combineListenablesData(event.map((e) => e as Loaded).toList());
        return Loaded<InputParameter>(result);
      }
    }).listen((event) {
      handleListenablesOutput(event);
    }, onError: handleListenablesError);
  }

  InputParameter combineListenablesData(List<Loaded> listenableData);

  void handleListenablesOutput(BlocState event) {
    if (event is Loaded<InputParameter>) {
      inputParameter = event.data;
      fetchData();
    } else {
      inputParameter = null;
      injectInputState(event);
    }
  }

  void handleListenablesError(e, s) {
    print(e);
    print(s);
    injectInputState(Error(createFailure(e)));
  }

  @override
  Future<void> close() {
    listenableSources.forEach((element) => element.removeListener(this));
    return super.close();
  }
}
