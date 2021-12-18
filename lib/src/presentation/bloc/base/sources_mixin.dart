import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/stateful_bloc.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/traffic_lights_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';

import 'listener_mixin.dart';
import 'state.dart';
import 'work.dart';

mixin SourcesMixin<Input, Output, State>
    on
        StatefulBloc<Output, State>,
        TrafficLightsMixin<State>,
        ListenerMixin<State> {
  late final List<ProviderMixin> providers;
  late final List<Stream<ProviderState>> sources;
  late final StreamSubscription _dataSubscription;

  final ValueNotifier<bool> listeningToSources = ValueNotifier(true);
  final throttleWindowDuration = Duration(milliseconds: 200);

  Work? _lastWork;
  Work? get lastWork {
    return _lastWork;
  }

  set lastWork(Work? work) {
    if (work != _lastWork) {
      _lastWork?.cancel();
    }
    _lastWork = work;
  }

  Stream<BlocState> get inputStream;

  @override
  get trafficLights => super.trafficLights..addAll([listeningToSources]);
  @override
  get subscriptions => super.subscriptions..addAll([_dataSubscription]);

  FutureOr<void> handleSourcesOutput(Work event);

  void pauseSources() {
    listeningToSources.value = false;
  }

  void resumeSources() {
    listeningToSources.value = true;
  }

  @mustCallSuper
  void trafficLightsChanged(bool green) {
    if (green) {
      _dataSubscription.resume();
    } else {
      _dataSubscription.pause();
    }
    super.trafficLightsChanged(green);
  }

  @override
  void init() {
    setupStreams();
    super.init();
  }

  bool _init = false;
  void setupStreams() {
    if (_init) return;
    _init = true;
    print(this.runtimeType);
    providers
        .whereType<ListenableMixin>()
        .forEach((element) => element.addListener(this));
    final newSources = [...sources, ...providers.map((e) => e.stream)];
    _dataSubscription = inputStream
        .switchMap<Tuple2<BlocState, List<ProviderState<dynamic>>>>((event) {
          if (newSources.isEmpty || event is Loading || event is Error) {
            return Stream.value(Tuple2(event, []));
          } else {
            return CombineLatestStream<ProviderState<dynamic>,
                    Tuple2<BlocState, List<ProviderState<dynamic>>>>(
                newSources, (a) => Tuple2(event, a));
          }
        })
        .throttleTime(throttleWindowDuration, trailing: true)
        .asyncMap((event) async {
          final work = Work.start(Loading());
          lastWork = work;
          var mainEvent = event.value1;
          if (mainEvent is Loading || mainEvent is Error) {
            return work.changeState(mainEvent);
          }
          mainEvent = mainEvent as Loaded<Input>;
          ProviderError? errorState = event.value2
                  .firstWhereOrNull((element) => element is ProviderError)
              as ProviderError<dynamic>?;
          if (errorState != null) {
            return work.changeState(Error(errorState.response));
          } else if (event.value2
              .any((element) => element is ProviderLoading)) {
            return work.changeState(Loading());
          } else {
            final result = await combineDataWithSources(mainEvent.data,
                event.value2.map((e) => (e as ProviderLoaded).data).toList());
            return work.changeState(Loaded<Input>(result));
          }
        })
        .where((event) => !event.isCancelled)
        .listen((event) {
          handleSourcesOutput(event);
        }, onError: handleSourcesError);
  }

  void handleSourcesError(e, s) {
    print(e);
    print(s);
    lastWork = Work.start(Error(createFailure(e, s)));
    handleSourcesOutput(_lastWork!);
  }

  FutureOr<Input> combineDataWithSources(Input data, List<dynamic> map) {
    return data;
  }

  @override
  Future<void> close() {
    providers
        .whereType<ListenableMixin>()
        .forEach((element) => element.removeListener(this));
    return super.close();
  }
}
