import 'package:api_bloc_base/src/domain/entity/base_profile.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/independence_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/lifecycle_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/worker/_index.dart';

mixin UserDependantWorkerMixin<Input, Output, Profile extends BaseProfile>
    on
        LifecycleWorkerMixin<Output>,
        IndependenceWorkerMixin<Input, Output>,
        UserDependantMixin<Input, Output, WorkerState<Output>, Profile> {
  WorkerState<Output> createLoadedState(Output data) {
    return UserDependentLoadedState<Output>(data, lastLogin);
  }

  WorkerState<Output> createErrorState(ResponseEntity response) {
    return UserDependentErrorState<Output>(response, lastLogin);
  }
}
