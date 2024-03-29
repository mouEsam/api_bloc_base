import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:flutter/cupertino.dart';

import '_index.dart';

abstract class StatefulBloc<Data, State extends BlocState>
    extends BaseCubit<State> {
  StatefulBloc(State initialState) : super(initialState);

  String get defaultErrorMessage => "Error in ${this.runtimeType}";

  bool get hasData;

  String extractErrorMessage(e, [s]) {
    print("Error in $this");
    print(e);
    print(s);
    try {
      return e.response as String;
    } catch (_) {
      try {
        return e.message as String;
      } catch (_) {
        return defaultErrorMessage;
      }
    }
  }

  void handleError(e, s) {
    print(e);
    print(s);
    emitError(createFailure(e, s));
  }

  @override
  @mustCallSuper
  void stateChanged(State nextState) {
    if (nextState is Loaded<Data>) {
      onDataEmitted(nextState.data);
    }
  }

  void onDataEmitted(Data data) {}

  Failure createFailure(e, [s]) {
    if (e is Failure) {
      return e;
    }
    return UnknownFailure(e, extractErrorMessage(e, s));
  }

  void clean() {}

  void emitState(State state);

  void emitLoading() {
    emit(createLoadingState());
  }

  void emitLoaded(Data data) {
    emit(createLoadedState(data));
  }

  void emitError(ResponseEntity response) {
    emit(createErrorState(response));
  }

  State createLoadingState();

  State createLoadedState(Data data);

  State createErrorState(ResponseEntity message);
}
