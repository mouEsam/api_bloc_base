import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:flutter/foundation.dart';

import 'work.dart';

mixin InputToOutput<Input, Output, State extends BlocState>
    on SourcesMixin<Input, Output, State> {
  bool get isSinkClosed;
  StreamSink<Work> get inputSink;

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
    if (!isSinkClosed) {
      lastWork = input;
      if (state is Loaded<Input>) {
        await handleInputToInject(state.data);
        input =
            input.changeState(Loaded(await convertInputToInject(state.data)));
      }
      inputSink.add(input);
    }
  }

  FutureOr<void> handleInputToInject(Input input) {}

  FutureOr<Input> convertInputToInject(Input input) {
    return input;
  }

  @mustCallSuper
  void handleSourcesOutput(work) async {
    final state = work.state;
    late final BlocState outputState;
    if (state is Loaded<Input>) {
      try {
        await handleInjectedInput(state.data);
        final input = await convertInput(state.data);
        await handleConvertedInput(input);
        final output = await convertInputToOutput(input);
        final newOutput = await convertOutput(output);
        await handleConvertedOutput(newOutput);
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
        output =
            output.changeState(Loaded(await convertOutputToInject(state.data)));
      } catch (e, s) {
        if (e is CancellationError) {
          return;
        } else {
          output = output.changeState(Error(createFailure(e, s)));
        }
      }
    }
    handleOutput(output);
  }

  FutureOr<void> handleOutputToInject(Output output) {}

  FutureOr<Output> convertOutputToInject(Output output) {
    return output;
  }

  void handleOutput(Work output);
}
