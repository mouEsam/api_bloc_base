import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/listenable_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/stateful_bloc.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/traffic_lights_mixin.dart';
import 'package:api_bloc_base/src/utils/box.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:listenable_stream/listenable_stream.dart';
import 'package:rxdart/rxdart.dart';

import 'independence_mixin.dart';
import 'listener_mixin.dart';

export 'state.dart';

mixin ParametersDependenceMixin<InputParameter, Input, Output,
        State extends BlocState>
    on
        StatefulBloc<Output, State>,
        TrafficLightsMixin<State>,
        IndependenceMixin<Input, Output, State>,
        ListenerMixin<State> {
  Box<InputParameter> _inputParameter = Box(null);

  InputParameter get inputParameter => _inputParameter.data;
  set inputParameter(InputParameter? inputParameter) =>
      _inputParameter.data = inputParameter;

  final ValueNotifier<bool> listeningToParametersSources = ValueNotifier(true);

  late final List<ListenableMixin<BlocState>> listenableParametersSources;
  late final List<Stream<BlocState>> listenableParametersStreams;

  late final StreamSubscription _streamParametersSubscription;

  // @override
  // get trafficLights => super.trafficLights..addAll([listeningToListenables]);

  @override
  get subscriptions =>
      super.subscriptions..addAll([_streamParametersSubscription]);

  void pauseParametersListenables() {
    listeningToParametersSources.value = false;
  }

  void resumeParametersListenables() {
    listeningToParametersSources.value = true;
  }

  @mustCallSuper
  void trafficLightsChanged(bool green) {
    if (green) {
      _streamParametersSubscription.resume();
    } else {
      _streamParametersSubscription.pause();
    }
    super.trafficLightsChanged(green);
  }

  @override
  void init() {
    setupListenableParametersDependence();
    super.init();
  }

  bool _init = false;
  void setupListenableParametersDependence() {
    if (_init) return;
    _init = true;
    listenableParametersSources.forEach((element) => element.addListener(this));
    final List<Stream<BlocState>> newSources = [
      ...listenableParametersStreams,
      ...listenableParametersSources.map((e) => e.stream)
    ];
    _streamParametersSubscription = listeningToParametersSources
        .toValueStream(replayValue: true)
        .where((event) => event)
        .switchMap((value) => CombineLatestStream(newSources, (a) => a))
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
      markNeedsRefetch();
    } else {
      inputParameter = null;
      injectInputState(event);
    }
  }

  void handleListenablesError(e, s) {
    print(e);
    print(s);
    injectInputState(Error(createFailure(e, s)));
  }

  @override
  Future<void> close() {
    listenableParametersSources
        .forEach((element) => element.removeListener(this));
    return super.close();
  }
}
