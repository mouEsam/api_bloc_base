import 'dart:async';

import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/listener_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/sources_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/state.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/visibility_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/worker/worker_bloc.dart';
import 'package:async/async.dart' as async;
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../provider/provider.dart' as provider;
import 'worker_state.dart';

export 'worker_state.dart';

abstract class ListenerBloc<Input, Output> extends WorkerBloc<Output>
    with
        ListenerMixin<WorkerState<Output>>,
        VisibilityMixin<WorkerState<Output>>,
        SourcesMixin<Input, Output, WorkerState<Output>> {
  late final StreamSubscription _outputSubscription;

  final _inputSubject = StreamController<BlocState>.broadcast();
  Stream<BlocState> get inputStream => _inputSubject.stream.shareValue();
  StreamSink<BlocState> get _inputSink => _inputSubject.sink;

  final _outputSubject = StreamController<BlocState>.broadcast();
  Stream<BlocState> get outputStream => _outputSubject.stream.shareValue();
  StreamSink<BlocState> get _outputSink => _outputSubject.sink;

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
    setupStreams();
    setupOutputStream();
  }

  void setupOutputStream() {
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
  void handleSourcesOutput(event) {
    late final BlocState outputState;
    if (event is Loaded<Input>) {
      try {
        final input = convertInput(event.data);
        final output = convertInputToOutput(input);
        final newOutput = convertOutput(output);
        outputState = Loaded<Output>(newOutput);
      } catch (e, s) {
        outputState = Error(Failure(extractErrorMessage(e)));
      }
    } else {
      outputState = event;
    }
    handleOutputState(outputState);
  }

  Output convertInputToOutput(Input input);

  @mustCallSuper
  void handleOutputState(BlocState event) {
    injectOutputState(event);
  }

  Input convertInput(Input input) {
    return input;
  }

  Output convertOutput(Output output) {
    return output;
  }

  void injectInput(Input input) {
    injectInputState(Loaded(input));
  }

  void injectInputState(BlocState input) {
    if (!_inputSubject.isClosed) {
      if (input is Loaded<Input>) {
        handleInputToInject(input.data);
        input = Loaded(convertInputToInject(input.data));
      }
      _inputSink.add(input);
    }
  }

  void handleInputToInject(Input input) {}

  Input convertInputToInject(Input input) {
    return input;
  }

  void injectOutput(Output output) {
    injectOutputState(Loaded(output));
  }

  @mustCallSuper
  void injectOutputState(BlocState output) {
    if (!_outputSubject.isClosed) {
      if (output is Loaded<Output>) {
        handleOutputToInject(output.data);
        output = Loaded(convertOutputToInject(output.data));
      }
      _outputSink.add(output);
    }
  }

  void handleOutputToInject(Output output) {}

  Output convertOutputToInject(Output output) {
    return output;
  }
}
