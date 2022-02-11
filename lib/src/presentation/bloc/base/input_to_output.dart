import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:flutter/foundation.dart';

import 'sources_mixin.dart';
import 'state.dart';
import 'work.dart';

mixin OutputInjectorMixin<Input, Output, State extends BlocState>
    on SourcesMixin<Input, Output, State> {
  @mustCallSuper
  void handleSourcesOutput(work) async {
    final state = work.state;
    late final BlocState outputState;
    void throwIfCancelled() => work.throwIfCancelled();
    if (state is Loaded<Input>) {
      try {
        throwIfCancelled();
        await handleInjectedInput(state.data);
        throwIfCancelled();
        final input = await convertInput(state.data);
        throwIfCancelled();
        await handleConvertedInput(input);
        throwIfCancelled();
        final output = await convertInputToOutput(input);
        throwIfCancelled();
        final newOutput = await convertOutput(output);
        throwIfCancelled();
        await handleConvertedOutput(newOutput);
        throwIfCancelled();
        outputState = Loaded<Output>(newOutput);
      } catch (e, s) {
        if (e is CancellationError) {
          return;
        } else {
          outputState = Error(createFailure(e, s));
        }
      }
    } else {
      outputState = state;
    }
    handleOutputState(work.changeState(outputState));
  }

  FutureOr<void> handleInjectedInput(Input input) {}
  FutureOr<void> handleConvertedOutput(Output output) {}
  FutureOr<void> handleConvertedInput(Input output) {}

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

  @mustCallSuper
  Future<void> injectOutput(Output output) async {
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
    if (state is Loaded<Output>) {
      try {
        await handleOutputToInject(state.data);
        output.throwIfCancelled();
        final newOutput = await convertOutputToInject(state.data);
        output = output.changeState(Loaded(newOutput));
      } catch (e, s) {
        if (e is CancellationError) {
          return;
        } else {
          output = output.changeState(Error(createFailure(e, s)));
        }
      }
    }
    if (!output.isCancelled) {
      handleOutput(output);
    }
  }

  FutureOr<void> handleOutputToInject(Output output) {}

  FutureOr<Output> convertOutputToInject(Output output) {
    return output;
  }

  void handleOutput(Work output);
}
