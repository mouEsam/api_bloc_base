import 'package:api_bloc_base/src/domain/entity/base_profile.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';

import 'provider.dart';
import 'user_dependant_state.dart';

mixin UserDependantProviderMixin<Input, Output, Profile extends BaseProfile>
    on
        LifecycleMixin<ProviderState<Output>>,
        IndependenceMixin<Input, Output, ProviderState<Output>>,
        UserDependantMixin<Input, Output, ProviderState<Output>, Profile> {
  ProviderState<Output> createLoadedState(Output data) {
    return UserDependentProviderLoadedState<Output>(data, lastLogin);
  }

  ProviderState<Output> createErrorState(ResponseEntity response) {
    return UserDependentProviderErrorState<Output>(response, lastLogin);
  }
}
