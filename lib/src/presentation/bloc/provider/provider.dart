import 'dart:async';

import 'package:api_bloc_base/src/data/repository/base_repository.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/independence_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/lifecycle_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/listenable_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/listener_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/sources_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/stateful_bloc.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/traffic_lights_mixin.dart';
import 'package:async/async.dart' as async;
import 'package:dartz/dartz.dart';
import 'package:rxdart/rxdart.dart';

import 'lifecycle_observer.dart';
import 'provider_mixin.dart';
import 'state.dart';

export 'state.dart';

class ProviderBloc<Data> extends StatefulBloc<Data, ProviderState<Data>>
    with
        ProviderMixin<Data>,
        TrafficLightsMixin<ProviderState<Data>>,
        LifecycleMixin<ProviderState<Data>>,
        ListenableMixin<ProviderState<Data>>,
        IndependenceMixin<Data, Data, ProviderState<Data>>,
        ListenerMixin<ProviderState<Data>>,
        SourcesMixin<Data, Data, ProviderState<Data>> {
  final Duration? refreshInterval = Duration(seconds: 30);
  final Duration? retryInterval = Duration(seconds: 30);

  final Result<Either<ResponseEntity, Data>>? singleDataSource;
  final Either<ResponseEntity, Stream<Data>>? streamDataSource;

  final LifecycleObserver? appLifecycleObserver;
  final List<ProviderBloc> providers;
  final List<Stream<ProviderState>> sources;

  final bool enableRefresh;
  final bool enableRetry;
  final bool canRunWithoutListeners;

  final BehaviorSubject<BlocState> _input = BehaviorSubject();
  Stream<BlocState> get inputStream => _input.shareValue();

  @override
  get subjects => [_dataSubject];

  final BehaviorSubject<Data?> _dataSubject = BehaviorSubject<Data?>();
  var _dataFuture = Completer<Data?>();
  var _stateFuture = Completer<ProviderState<Data>>();
  Data? get latestData => _dataSubject.valueOrNull;

  Stream<Data?> get dataStream =>
      async.LazyStream(() => _dataSubject.shareValue())
          .asBroadcastStream(onCancel: (c) => c.cancel());

  ProviderBloc({
    Data? initialDate,
    this.singleDataSource,
    this.streamDataSource,
    this.appLifecycleObserver,
    this.sources = const [],
    this.providers = const [],
    this.enableRefresh = true,
    this.enableRetry = true,
    this.canRunWithoutListeners = true,
    bool getOnCreate = true,
  }) : super(ProviderLoading()) {
    setupInitialData(initialDate);
    if (getOnCreate) {
      fetchData();
    }
  }

  void init() {}

  void setupInitialData(Data? initialDate) {
    if (initialDate is Data) {
      injectInput(initialDate);
    }
  }

  void handleSourcesOutput(BlocState input) {
    emitState(input);
  }

  void clean() {
    _dataSubject.value = null;
    _dataFuture = Completer();
  }

  void onChange(change) {
    super.onChange(change);
    setupTimer();
    handleState(change.nextState);
  }

  void handleState(state) {
    if (state is ProviderLoaded<Data>) {
      Data data = state.data;
      _dataSubject.add(data);
      if (_dataFuture.isCompleted) {
        _dataFuture = Completer<Data>();
      }
      _dataFuture.complete(data);
    } else if (state is Invalidated) {
      clean();
      fetchData();
      return;
    }
    if (_stateFuture.isCompleted) {
      _stateFuture = Completer<ProviderState<Data>>();
    }
    _stateFuture.complete(state);
  }

  void injectInput(Data input) {
    injectInputState(Loaded(input));
  }

  void injectInputState(BlocState input) {
    _input.add(input);
  }

  void trafficLightsChanged(bool green) {
    if (green) {
      resumeSources();
    } else {
      pauseSources();
    }
    super.trafficLightsChanged(green);
  }
}
