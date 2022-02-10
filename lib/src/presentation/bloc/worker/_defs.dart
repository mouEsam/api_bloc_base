import 'package:api_bloc_base/src/domain/entity/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/dependence_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/independence_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/input_to_output.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/lifecycle_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/listenable_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/listener_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/provider_listener_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/same_input_output_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/sources_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/traffic_lights_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/user_dependant_mixin.dart';

import 'worker_state.dart';

typedef SameInputOutputWorkerMixin<Output>
    = SameInputOutputMixin<Output, WorkerState<Output>>;
typedef StatefulWorkerBloc<Output> = StatefulBloc<Output, WorkerState<Output>>;
typedef LifecycleWorkerMixin<Output> = LifecycleMixin<WorkerState<Output>>;
typedef TrafficLightsWorkerMixin<Output>
    = TrafficLightsMixin<WorkerState<Output>>;
typedef ListenableWorkerMixin<Output> = ListenableMixin<WorkerState<Output>>;
typedef ListenerWorkerMixin<Output> = ListenerMixin<WorkerState<Output>>;
typedef IndependenceWorkerMixin<Input, Output>
    = IndependenceMixin<Input, Output, WorkerState<Output>>;
typedef SourcesWorkerMixin<Input, Output>
    = SourcesMixin<Input, Output, WorkerState<Output>>;
typedef InputToOutputWorkerMixin<Input, Output>
    = InputToOutput<Input, Output, WorkerState<Output>>;
typedef ProviderListenerWorkerMixin<Input, Output>
    = ProviderListenerMixin<Input, Output, WorkerState<Output>>;
typedef VisibilityWorkerMixin<Output> = VisibilityMixin<WorkerState<Output>>;
typedef ParametersDependenceWorkerMixin<ParameterType, Input, Output>
    = ParametersDependenceMixin<ParameterType, Input, Output,
        WorkerState<Output>>;
typedef UserDependantWorkerMixin<Input, Output, Profile extends BaseProfile<Profile>>
    = UserDependantMixin<Input, Output, WorkerState<Output>, Profile>;
