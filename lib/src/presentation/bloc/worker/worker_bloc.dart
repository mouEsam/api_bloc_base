import 'package:api_bloc_base/src/domain/entity/response_entity.dart';

import '../../../utils/box.dart';
import '../base/stateful_bloc.dart';
import 'worker_mixin.dart';
import 'worker_state.dart';

abstract class WorkerBloc<Output>
    extends StatefulBloc<Output, WorkerState<Output>> with WorkerMixin<Output> {
  WorkerState<Output> get initialState => LoadedState(currentData);

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

  bool get hasValue => _output != null;
  Output get currentData => _output!.data;
  Output? get safeData => _output?.nullableData;
  set currentData(Output data) {
    _output = Box(data);
    emitCurrent();
  }

  void clear() {
    _output = null;
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
