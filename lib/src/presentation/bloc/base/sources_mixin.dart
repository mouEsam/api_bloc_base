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

  // @mustCallSuper
  // void trafficLightsChanged(bool green) {
  //   if (green) {
  //     _dataSubscription.resume();
  //   } else {
  //     _dataSubscription.pause();
  //   }
  //   super.trafficLightsChanged(green);
  // }

  @override
  void init() {
    setupStreams();
    super.init();
  }

  bool _init = false;
  void setupStreams() {
    if (_init) return;
    _init = true;
    providers
        .whereType<ListenableMixin>()
        .forEach((element) => element.addListener(this));
    // final newSources = [...sources, ...providers.map((e) => e.stream)];
    // _dataSubscription = inputStream
    //     .cast<BlocState>()
    //     .switchMap((event) {
    //       if (newSources.isEmpty || event is Loading || event is Error) {
    //         return Stream.value(Tuple2<BlocState, List<BlocState>>(event, []));
    //       } else {
    //         return CombineLatestStream<BlocState,
    //             Tuple2<BlocState, List<BlocState>>>(newSources, (a) {
    //           return Tuple2(event, a);
    //         });
    //       }
    //     })
    //     .asyncMap((event) {
    //       return whenActive(() => event);
    //     })
    final newSources = [
      inputStream.cast<BlocState>(),
      ...sources,
      ...providers.map((e) => e.stream.shareValue())
    ];
    _dataSubscription =
        CombineLatestStream<BlocState, Tuple2<BlocState, List<BlocState>>>(
                newSources, (a) {
      return Tuple2(a[0], a.skip(1).toList());
    })
            .asyncMap((event) {
              return whenActive(() => event);
            })
            .throttleTime(throttleWindowDuration, trailing: true)
            .asyncMap((event) async {
              final work = Work.start(state);
              lastWork = work;
              var mainEvent = event.value1;
              if (mainEvent is Loading || mainEvent is Error) {
                return work.changeState(mainEvent);
              } else {
                mainEvent = mainEvent as Loaded<Input>;
                Error? errorState = event.value2
                    .firstWhereOrNull((element) => element is Error) as Error?;
                if (errorState != null) {
                  return work.changeState(errorState);
                } else if (event.value2.whereType<Loading>().isNotEmpty) {
                  return null;
                } else {
                  final loaded = event.value2.whereType<Loaded>().toList();
                  final result =
                      await combineDataWithStates(mainEvent.data, loaded);
                  return work.changeState(result);
                }
              }
            })
            .whereType<Work>()
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

  FutureOr<BlocState> combineDataWithStates(Input data, Iterable<Loaded> map) {
    return combineDataWithSources(data, map.map((e) => e.data));
  }

  FutureOr<BlocState> combineDataWithSources(Input data, Iterable map) {
    return Loaded<Input>(data);
  }

  @override
  Future<void> close() {
    providers
        .whereType<ListenableMixin>()
        .forEach((element) => element.removeListener(this));
    return super.close();
  }
}
