import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/base_bloc.dart';

import '_index.dart';
import 'state.dart';

abstract class StatefulBloc<Data, State extends BlocState>
    extends BaseCubit<State> {
  StatefulBloc(State initialState) : super(initialState);

  String get defaultErrorMessage => "Error in ${this.runtimeType}";

  bool get hasData;

  String extractErrorMessage(e, [s]) {
    print(e);
    print(s);
    try {
      return e.response;
    } catch (_) {
      try {
        return e.message;
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

  Failure createFailure(e, [s]) {
    if (e is Failure) {
      return e;
    }
    return Failure(extractErrorMessage(e, s));
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
