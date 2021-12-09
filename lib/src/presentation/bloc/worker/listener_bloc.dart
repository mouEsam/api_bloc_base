import 'dart:async';

import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/listener_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/sources_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/state.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/traffic_lights_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/visibility_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/work.dart';
import 'package:api_bloc_base/src/presentation/bloc/worker/worker_bloc.dart';
import 'package:async/async.dart' as async;
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../provider/provider.dart' as provider;
import 'worker_state.dart';

export 'worker_state.dart';

abstract class ListenerBloc<Input, Output> extends WorkerBloc<Output>
    with
        TrafficLightsMixin<WorkerState<Output>>,
        ListenerMixin<WorkerState<Output>>,
        VisibilityMixin<WorkerState<Output>>,
        SourcesMixin<Input, Output, WorkerState<Output>> {
  late final StreamSubscription _outputSubscription;

  final _inputSubject = StreamController<Work>.broadcast();
  Stream<BlocState> get inputStream => _inputSubject.stream
      .shareValue()
      .where((event) => !event.isCancelled)
      .map((event) => event.state);
  StreamSink<Work> get _inputSink => _inputSubject.sink;

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

  get sinks => [_inputSubject, _outputSubject];
  get subscriptions => super.subscriptions..addAll([_outputSubscription]);

  final List<Stream<provider.ProviderState>> sources;
  final List<provider.ProviderBloc> providers;

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

  Output convertInjectedOutput(Output output) {
    return output;
  }

  void handleInjectedOutput(Output output) {}

  void setData(Output event) {
    handleInjectedOutput(event);
    currentData = convertInjectedOutput(event);
    emitCurrent();
  }

  @mustCallSuper
  void handleErrorState(provider.ProviderError<Input> errorState) {
    emitError(errorState.response);
  }

  @mustCallSuper
  void handleLoadingState(provider.ProviderLoading<Input> loadingState) {
    emitLoading();
  }

  @mustCallSuper
  handleSourcesOutput(work) async {
    final state = work.state;
    late final BlocState outputState;
    if (state is Loaded<Input>) {
      try {
        final input = await convertInput(state.data);
        final output = await convertInputToOutput(input);
        final newOutput = await convertOutput(output);
        outputState = Loaded<Output>(newOutput);
      } catch (e, s) {
        outputState = Error(Failure(extractErrorMessage(e)));
      }
    } else {
      outputState = state;
    }
    handleOutputState(work.changeState(outputState));
  }

  FutureOr<Output> convertInputToOutput(Input input);

  @mustCallSuper
  void handleOutputState(Work event) {
    injectOutputWork(event);
  }

  FutureOr<Input> convertInput(Input input) {
    return input;
  }

  FutureOr<Output> convertOutput(Output output) {
    return output;
  }

  FutureOr<void> injectInput(Input input) async {
    await injectInputState(Loaded(input));
  }

  FutureOr<void> injectInputState(BlocState state) async {
    final work = Work.start(state);
    lastWork = work;
    await injectInputWork(work);
  }

  FutureOr<void> injectInputWork(Work input) async {
    final state = input.state;
    if (!_inputSubject.isClosed) {
      lastWork = input;
      if (state is Loaded<Input>) {
        await handleInputToInject(state.data);
        input =
            input.changeState(Loaded(await convertInputToInject(state.data)));
      }
      _inputSink.add(input);
    }
  }

  FutureOr<void> handleInputToInject(Input input) {}

  FutureOr<Input> convertInputToInject(Input input) {
    return input;
  }

  FutureOr<void> injectOutput(Output output) async {
    await injectOutputState(Loaded(output));
  }

  @mustCallSuper
  Future<void> injectOutputState(BlocState state) async {
    final work = Work.start(state);
    lastWork = work;
    await injectOutputWork(work);
  }

  @mustCallSuper
  Future<void> injectOutputWork(Work output) async {
    final state = output.state;
    if (!_outputSubject.isClosed) {
      if (state is Loaded<Output>) {
        await handleOutputToInject(state.data);
        output =
            output.changeState(Loaded(await convertOutputToInject(state.data)));
      }
      _outputSink.add(output);
    }
  }

  FutureOr<void> handleOutputToInject(Output output) {}

  FutureOr<Output> convertOutputToInject(Output output) {
    return output;
  }
}
