import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/_index.dart';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:listenable_stream/listenable_stream.dart';
import 'package:rxdart/rxdart.dart';

import 'listenable_mixin.dart';
import 'listener_mixin.dart';
import 'traffic_lights_mixin.dart';
import 'work.dart';

class _StateComplex extends Equatable {
  final bool isGreen;
  final BlocState state;
  final List<BlocState> states;

  const _StateComplex({
    required this.isGreen,
    required this.state,
    required this.states,
  });

  @override
  List<Object?> get props => [state, states];
}

mixin SourcesMixin<Input, Output, State extends BlocState>
    on
        StatefulBloc<Output, State>,
        TrafficLightsMixin<State>,
        ListenerMixin<State> {
  late final List<ProviderMixin> providers;
  late final List<Stream<BlocState>> sources;
  late final StreamSubscription _dataSubscription;

  final ValueNotifier<bool> listeningToSources = ValueNotifier(true);
  final throttleWindowDuration = const Duration(milliseconds: 200);

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
  List<ValueListenable<bool>> get trafficLights =>
      super.trafficLights..addAll([listeningToSources]);

  @override
  Set<StreamSubscription?> get subscriptions =>
      super.subscriptions..addAll([_dataSubscription]);

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
  Completer<Tuple2<BlocState, List<BlocState>>?>? _futureState;

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
    final combinedStreams =
        CombineLatestStream<BlocState, List<BlocState>>(newSources, (a) => a);
    final isGreenStream = isGreen.toValueStream(replayValue: true);
    final stream =
        CombineLatestStream.combine2<bool, List<BlocState>, _StateComplex>(
      isGreenStream,
      combinedStreams,
      (isGreen, list) {
        final mainState = list[0];
        final states = list.skip(1).toList();
        return _StateComplex(
          isGreen: isGreen,
          state: mainState,
          states: states,
        );
      },
    ).where((event) {
      final state = event.state;
      bool isUrgent(BlocState state) {
        return state is UrgentState && state.isUrgent;
      }

      if (event.isGreen || isUrgent(state) || event.states.any(isUrgent)) {
        return true;
      } else {
        return false;
      }
    });
    _dataSubscription = stream
        .throttleTime(throttleWindowDuration, trailing: true)
        .asyncMap((event) async {
          final completer = _futureState;
          if (completer != null && !completer.isCompleted) {
            completer.complete();
          }
          final work = Work.start(state);
          lastWork = work;
          var mainEvent = event.state;
          if (mainEvent is Loading || mainEvent is Error) {
            return work.changeState(mainEvent);
          } else {
            mainEvent = mainEvent as Loaded<Input>;
            final errorState = event.states.whereType<Error>().firstOrNull;
            if (errorState != null) {
              return work.changeState(errorState);
            } else if (event.states.whereType<Loading>().isNotEmpty) {
              return null;
            } else {
              final loaded = event.states.whereType<Loaded>().toList();
              final result =
                  await combineDataWithStates(mainEvent.data, loaded);
              return work.changeState(result);
            }
          }
        })
        .whereType<Work>()
        .where((event) => !event.isCancelled)
        .listen(
          (event) {
            handleSourcesOutput(event);
          },
          onError: handleSourcesError,
        );
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
