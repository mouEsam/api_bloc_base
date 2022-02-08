import 'package:api_bloc_base/src/domain/entity/base_profile.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/lifecycle_mixin.dart';

import '_defs.dart';
import 'provider.dart';
import 'user_dependant_state.dart';

mixin UserDependantProviderStateMixin<Input, Output,
        Profile extends BaseProfile<Profile>>
    on
        LifecycleMixin<ProviderState<Output>>,
        IndependenceProviderMixin<Input, Output>,
        UserDependantProviderMixin<Input, Output, Profile> {
  ProviderState<Output> createLoadedState(Output data) {
    return UserDependentProviderLoadedState<Output>(data, lastLogin);
  }

  ProviderState<Output> createErrorState(ResponseEntity response) {
    return UserDependentProviderErrorState<Output>(response, lastLogin);
  }
}
