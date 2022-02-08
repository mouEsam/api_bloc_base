import 'package:api_bloc_base/src/domain/entity/base_profile.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/worker/_index.dart';

mixin UserDependantWorkerStateMixin<Input, Output, Profile extends BaseProfile<Profile>>
    on
        LifecycleWorkerMixin<Output>,
        IndependenceWorkerMixin<Input, Output>,
        UserDependantWorkerMixin<Input, Output, Profile> {
  WorkerState<Output> createLoadedState(Output data) {
    return UserDependentLoadedState<Output>(data, lastLogin);
  }

  WorkerState<Output> createErrorState(ResponseEntity response) {
    return UserDependentErrorState<Output>(response, lastLogin);
  }
}
