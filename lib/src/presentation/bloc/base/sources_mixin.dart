import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/_index.dart';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';

import 'listenable_mixin.dart';
import 'listener_mixin.dart';
import 'traffic_lights_mixin.dart';
import 'work.dart';

mixin SourcesMixin<Input, Output, State extends BlocState>
    on
        StatefulBloc<Output, State>,
        TrafficLightsMixin<State>,
        ListenerMixin<State> {
  late final List<ProviderMixin> providers;
  late final List<Stream<BlocState>> sources;
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
  void clean() {
    super.clean();
    _combined = false;
  }

  @override
  void init() {
    setupStreams();
    super.init();
  }

  bool _combined = false;
  bool _init = false;
  void setupStreams() {
    if (_init) return;
    _init = true;
    print(this.runtimeType);
    providers
        .whereType<ListenableMixin>()
        .forEach((element) => element.addListener(this));
    final newSources = [...sources, ...providers.map((e) => e.stream)];
    final _stream = inputStream;
    var _lastValue;
    _dataSubscription = _stream
        .doOnData((event) {
          if (event is Loaded) {
            if (event.data != _lastValue) {
              _combined = false;
            }
            _lastValue = event.data;
          }
        })
        .cast<BlocState>()
        .switchMap((event) {
          if (newSources.isEmpty || event is Loading || event is Error) {
            return Stream.value(Tuple2<BlocState, List<BlocState>>(event, []));
          } else {
            return CombineLatestStream<BlocState,
                        Tuple2<BlocState, List<BlocState>>>(
                    newSources, (a) => Tuple2(event, a))
                .asBroadcastStream(onCancel: (c) => c.cancel());
          }
        })
        .throttleTime(throttleWindowDuration, trailing: true)
        .asyncMap((event) async {
          final work = Work.start(Loading());
          lastWork = work;
          var mainEvent = event.value1;
          if (mainEvent is Loading || mainEvent is Error) {
            return work.changeState(mainEvent);
          } else {
            mainEvent = mainEvent as Loaded<Input>;
            Error? errorState = event.value2
                .firstWhereOrNull((element) => element is Error) as Error?;
            if (errorState != null) {
              return work.changeState(Error(errorState.response));
            } else if (event.value2.every((element) => element is Loaded)) {
              _combined = true;
              final result = await combineDataWithSources(mainEvent.data,
                  event.value2.map((e) => (e as Loaded).data).toList());
              return work.changeState(Loaded<Input>(result));
            } else {
              if (_combined) {
                return work.changeState(mainEvent);
              } else {
                return work.changeState(Loading());
              }
            }
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
