import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:rxdart/rxdart.dart';

import 'input_sink.dart';
import 'sources_mixin.dart';
import 'state.dart';
import 'work.dart';

mixin StreamInputMixin<Input, Output, State extends BlocState>
    on
        InputSinkMixin<Input, Output, State>,
        SourcesMixin<Input, Output, State> {
  final _inputSubject = StreamController<Work>.broadcast();

  @override
  Stream<BlocState> get inputStream => _inputSubject.stream
      .shareValue()
      .where((event) => !event.isCancelled)
      .map((event) => event.state);

  bool get isSinkClosed => _inputSubject.isClosed;

  StreamSink<Work> get inputSink => _inputSubject.sink;

  @override
  Set<StreamSink> get sinks => super.sinks..addAll([_inputSubject]);

  @override
  void handleInput(Work input) {
    inputSink.add(input);
  }
}
