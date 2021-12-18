import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/user_dependant_state.dart';
import 'package:api_bloc_base/src/presentation/bloc/worker/_index.dart';

class UserDependentLoadedState<T> extends LoadedState<T>
    implements UserDependentState {
  final dynamic tag;

  const UserDependentLoadedState(T data, this.tag) : super(data);

  @override
  get props => super.props..addAll([tag]);
}

class UserDependentErrorState<T> extends ErrorState<T>
    implements UserDependentState {
  final dynamic tag;

  const UserDependentErrorState(ResponseEntity response, this.tag)
      : super(response);

  @override
  get props => super.props..addAll([tag]);
}
