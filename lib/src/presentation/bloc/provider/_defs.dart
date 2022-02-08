import 'package:api_bloc_base/src/domain/entity/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/dependence_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/independence_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/input_to_output.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/lifecycle_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/listenable_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/listener_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/same_input_output_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/sources_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/stateful_bloc.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/traffic_lights_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/user_dependant_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/_index.dart';

typedef SameInputOutputProviderMixin<Output>
    = SameInputOutputMixin<Output, ProviderState<Output>>;
typedef StatefulProviderBloc<Output>
    = StatefulBloc<Output, ProviderState<Output>>;
typedef LifecycleProviderMixin<Output> = LifecycleMixin<ProviderState<Output>>;
typedef TrafficLightsProviderMixin<Output>
    = TrafficLightsMixin<ProviderState<Output>>;
typedef ListenableProviderMixin<Output>
    = ListenableMixin<ProviderState<Output>>;
typedef ListenerStateProviderMixin<Output>
    = ListenerMixin<ProviderState<Output>>;
typedef IndependenceProviderMixin<Input, Output>
    = IndependenceMixin<Input, Output, ProviderState<Output>>;
typedef SourcesProviderMixin<Input, Output>
    = SourcesMixin<Input, Output, ProviderState<Output>>;
typedef InputToOutputProviderMixin<Input, Output>
    = InputToOutput<Input, Output, ProviderState<Output>>;
typedef ParametersDependenceProviderMixin<ParameterType, Input, Output>
    = ParametersDependenceMixin<ParameterType, Input, Output,
        ProviderState<Output>>;
typedef UserDependantProviderMixin<Input, Output, Profile extends BaseProfile>
    = UserDependantMixin<Input, Output, ProviderState<Output>, Profile>;