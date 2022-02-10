import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/state.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/work.dart';
import 'package:async/async.dart' as async;
import 'package:dartz/dartz.dart';
import 'package:rxdart/rxdart.dart';

import 'lifecycle_observer.dart';
import 'provider_mixin.dart';
import 'state.dart';
import '_defs.dart';

export 'state.dart';

abstract class ProviderBloc<Input, Output> extends StatefulProviderBloc<Output>
    with
        ProviderMixin<Output>,
        TrafficLightsProviderMixin<Output>,
        LifecycleProviderMixin<Output>,
        ListenableProviderMixin<Output>,
        ListenerStateProviderMixin<Output>,
        SourcesProviderMixin<Input, Output>,
        InputToOutputProviderMixin<Input, Output> {
  final LifecycleObserver? appLifecycleObserver;
  final List<ProviderMixin> providers;
  final List<Stream<ProviderState>> sources;

  final bool canRunWithoutListeners;

  final _inputSubject = StreamController<Work>.broadcast();
  Stream<BlocState> get inputStream => _inputSubject.stream
      .shareValue()
      .where((event) => !event.isCancelled)
      .map((event) => event.state);
  bool get isSinkClosed => _inputSubject.isClosed;
  StreamSink<Work> get inputSink => _inputSubject.sink;

  @override
  get sinks => [inputSink];
  @override
  get subjects => [_dataSubject];

  final BehaviorSubject<Output?> _dataSubject = BehaviorSubject<Output?>();
  var _dataFuture = Completer<Output?>();
  var _stateFuture = Completer<ProviderState<Output>>();
  Future<Output?> get dataFuture => _dataFuture.future;
  Future<ProviderState<Output>> get stateFuture => _stateFuture.future;
  bool get hasData => latestData != null;
  Output? get latestData => _dataSubject.valueOrNull;

  Stream<Output?> get dataStream =>
      async.LazyStream(() => _dataSubject.shareValue())
          .asBroadcastStream(onCancel: (c) => c.cancel());

  ProviderBloc({
    Input? initialInput,
    this.appLifecycleObserver,
    this.sources = const [],
    this.providers = const [],
    this.canRunWithoutListeners = true,
  }) : super(ProviderLoading()) {
    setupInitialData(initialInput);

  }

  void setupInitialData(Input? initialDate) {
    if (initialDate is Input) {
      injectInput(initialDate);
    }
  }

  void clean() {
    _dataSubject.value = null;
    _dataFuture = Completer();
    super.clean();
  }

  void stateChanged(ProviderState<Output> state) {
    if (state is ProviderLoaded<Output>) {
      Output data = state.data;
      _dataSubject.add(data);
      if (_dataFuture.isCompleted) {
        _dataFuture = Completer<Output>();
      }
      _dataFuture.complete(data);
    } else if (state is Invalidated) {
      refetchData();
      return;
    }
    if (_stateFuture.isCompleted) {
      _stateFuture = Completer<ProviderState<Output>>();
    }
    _stateFuture.complete(state);
  }

  @override
  void handleOutput(Work output) {
    if (!output.isCancelled) {
      emitState(output.state);
    }
  }
}
