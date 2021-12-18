import 'package:api_bloc_base/src/domain/entity/base_profile.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/worker/_index.dart';

import 'user_dependant_state.dart';

mixin UserDependantWorkerMixin<Input, Output, Profile extends BaseProfile>
    on
        LifecycleMixin<WorkerState<Output>>,
        IndependenceMixin<Input, Output, WorkerState<Output>>,
        UserDependantMixin<Input, Output, WorkerState<Output>, Profile> {
  WorkerState<Output> createLoadedState(Output data) {
    return UserDependentLoadedState<Output>(data, lastLogin);
  }

  WorkerState<Output> createErrorState(ResponseEntity response) {
    return UserDependentErrorState<Output>(response, lastLogin);
  }
}
