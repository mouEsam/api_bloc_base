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
import 'state.dart';

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
  final ValueNotifier<bool> _parameterIsReady = ValueNotifier(false);

  late final List<ListenableMixin<BlocState>> parametersSources = [];
  late final List<Stream<BlocState>> parametersSourceStreams = [];

  late final StreamSubscription _streamParametersSubscription;

  @override
  get trafficLights => super.trafficLights..addAll([_parameterIsReady]);

  @override
  get subscriptions =>
      super.subscriptions..addAll([_streamParametersSubscription]);

  void pauseParametersSources() {
    listeningToParametersSources.value = false;
  }

  void resumeParametersSources() {
    listeningToParametersSources.value = true;
  }

  // @mustCallSuper
  // void trafficLightsChanged(bool green) {
  //   if (green) {
  //     _streamParametersSubscription.resume();
  //   } else {
  //     _streamParametersSubscription.pause();
  //   }
  //   super.trafficLightsChanged(green);
  // }

  @override
  void init() {
    setupListenableParametersDependence();
    super.init();
  }

  bool _init = false;
  void setupListenableParametersDependence() {
    if (_init) return;
    _init = true;
    parametersSources.forEach((element) => element.addListener(this));
    final List<Stream<BlocState>> newSources = [
      ...parametersSourceStreams,
      ...parametersSources.map((e) => e.stream)
    ];
    _streamParametersSubscription = CombineLatestStream([
      listeningToSources
          .toValueStream(replayValue: true)
          .where((event) => event),
      ...newSources
    ], (s) => s.skip(1).toList()).map((event) {
      Error? errorState =
          event.firstWhereOrNull((element) => element is Error) as Error?;
      if (errorState != null) {
        return Error(errorState.response);
      } else if (event.any((element) => element is Loading)) {
        return Loading();
      } else {
        return combineParametersData(event.map((e) => e as Loaded).toList());
      }
    }).listen((event) {
      handleParameterOutput(event);
    }, onError: handleParameterError);
  }

  BlocState combineParametersData(List<Loaded> listenableData);

  void handleParameterOutput(BlocState event) {
    if (event is Loaded<InputParameter>) {
      inputParameter = event.data;
      _parameterIsReady.value = true;
      markNeedsRefetch();
    } else {
      inputParameter = null;
      _parameterIsReady.value = false;
      if (event is Error && event is! UrgentState) {
        injectInputState(UrgentError(event.response));
      } else {
        injectInputState(event);
      }
    }
  }

  void handleParameterError(e, s) {
    print(e);
    print(s);
    handleParameterOutput(Error(createFailure(e, s)));
  }

  @override
  Future<void> close() {
    parametersSources.forEach((element) => element.removeListener(this));
    return super.close();
  }
}
