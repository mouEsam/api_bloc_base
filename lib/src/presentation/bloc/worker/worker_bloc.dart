import 'package:api_bloc_base/src/domain/entity/response_entity.dart';

import '../../../utils/box.dart';
import '../base/stateful_bloc.dart';
import 'worker_mixin.dart';
import 'worker_state.dart';
import '_defs.dart';

class WorkerBloc<Output> extends StatefulWorkerBloc<Output>
    with WorkerMixin<Output> {
  WorkerState<Output> get initialState =>
      hasData ? createLoadedState(currentData) : createLoadingState();

  WorkerBloc.work(Output currentData) : super(LoadingState()) {
    this.currentData = currentData;
    emit(initialState);
  }

  WorkerBloc(Output? currentData) : super(LoadingState()) {
    if (currentData is Output) {
      this.currentData = currentData!;
    }
    emit(initialState);
  }

  Box<Output>? _output;

  bool get hasData => _output != null;
  Output get currentData => _output!.data;
  Output? get safeData => _output?.nullableData;
  set currentData(Output data) {
    _output = Box(data);
    emitCurrent();
  }

  void clean() {
    _output = null;
  }

  void emitData(Output event) {
    currentData = event;
  }

  WorkerState<Output> createLoadingState() {
    return LoadingState<Output>();
  }

  WorkerState<Output> createLoadedState(Output data) {
    return LoadedState<Output>(data);
  }

  WorkerState<Output> createErrorState(ResponseEntity response) {
    return ErrorState<Output>(response);
  }
}
