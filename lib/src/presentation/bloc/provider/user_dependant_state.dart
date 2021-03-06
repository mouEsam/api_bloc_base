import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/user_dependant_state.dart';

import 'state.dart';

class UserDependentProviderLoadedState<T> extends ProviderLoaded<T>
    implements UserDependentState {
  final dynamic tag;

  const UserDependentProviderLoadedState(T data, this.tag) : super(data);

  @override
  get props => super.props..addAll([tag]);
}

class UserDependentProviderErrorState<T> extends ProviderError<T>
    implements UserDependentState {
  final dynamic tag;

  const UserDependentProviderErrorState(ResponseEntity response, this.tag)
      : super(response);

  @override
  get props => super.props..addAll([tag]);
}
