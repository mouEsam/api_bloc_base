import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/state.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/work.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/worker/worker_bloc.dart';
import 'package:async/async.dart' as async;
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../provider/provider.dart' as provider;
import '_defs.dart';
import 'worker_state.dart';

export 'worker_state.dart';

abstract class ListenerBloc<Input, Output> extends WorkerBloc<Output>
    with
        TrafficLightsWorkerMixin<Output>,
        ListenerWorkerMixin<Output>,
        VisibilityWorkerMixin<Output>,
        SourcesWorkerMixin<Input, Output>,
        OutputInjectorWorkerMixin<Input, Output> {
  late final StreamSubscription _outputSubscription;

  final _outputSubject = StreamController<Work>.broadcast();
  Stream<BlocState> get outputStream => _outputSubject.stream
      .shareValue()
      .where((event) => !event.isCancelled)
      .map((event) => event.state);
  StreamSink<Work> get _outputSink => _outputSubject.sink;

  Stream<provider.ProviderState<Output>> get providerStream =>
      async.LazyStream(() => stream
          .map((event) {
            if (event is LoadingState<Output>) {
              return provider.ProviderLoading<Output>();
            } else if (event is LoadedState<Output>) {
              return provider.ProviderLoaded<Output>(event.data);
            } else if (event is ErrorState<Output>) {
              return provider.ProviderError<Output>(event.response);
            }
          })
          .whereType<provider.ProviderState<Output>>()
          .asBroadcastStream(onCancel: (sub) => sub.cancel()));

  get sinks => super.sinks..addAll([_outputSubject]);
  get subscriptions => super.subscriptions..addAll([_outputSubscription]);

  final List<Stream<provider.ProviderState>> sources;
  final List<ProviderMixin> providers;

  ListenerBloc(this.sources, this.providers, {Output? currentData})
      : super(currentData) {
    init();
  }

  void init() {
    super.init();
    setupOutputStream();
  }

  bool _init = false;
  void setupOutputStream() {
    if (_init) return;
    _init = true;
    _outputSubscription = outputStream.listen(emitState, onError: handleError);
  }

  @mustCallSuper
  void handleErrorState(provider.ProviderError<Input> errorState) {
    emitError(errorState.response);
  }

  @mustCallSuper
  void handleLoadingState(provider.ProviderLoading<Input> loadingState) {
    emitLoading();
  }

  @override
  void handleOutput(Work output) {
    if (!_outputSubject.isClosed) {
      _outputSink.add(output);
    }
  }
}
