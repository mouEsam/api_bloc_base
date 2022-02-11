import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';

import 'sources_mixin.dart';
import 'state.dart';
import 'work.dart';

mixin InputSinkMixin<Input, Output, State extends BlocState>
    on SourcesMixin<Input, Output, State> {
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
    lastWork = input;
    if (state is Loaded<Input>) {
      await handleInputToInject(state.data);
      input = input.changeState(Loaded(await convertInputToInject(state.data)));
    }
    handleInput(input);
  }

  FutureOr<void> handleInputToInject(Input input) {}

  FutureOr<Input> convertInputToInject(Input input) {
    return input;
  }

  void handleInput(Work input);
}
