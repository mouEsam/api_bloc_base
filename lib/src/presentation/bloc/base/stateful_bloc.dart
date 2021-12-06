import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/base_bloc.dart';

abstract class StatefulBloc<Data, State> extends BaseCubit<State> {
  StatefulBloc(State initialState) : super(initialState);

  String get defaultErrorMessage => "Error in ${this.runtimeType}";

  String extractErrorMessage(e) {
    try {
      return e.response;
    } catch (_) {
      return defaultErrorMessage;
    }
  }

  void handleError(e, s) {
    print(e);
    print(s);
    emitError(createFailure(e));
  }

  Failure createFailure(e) {
    return Failure(extractErrorMessage(e));
  }

  void clean();

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
