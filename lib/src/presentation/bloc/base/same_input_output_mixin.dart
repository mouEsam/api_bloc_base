import 'package:api_bloc_base/src/presentation/bloc/base/input_to_output.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/state.dart';

mixin SameInputOutputMixin<Data, State extends BlocState>
    on OutputInjectorMixin<Data, Data, State> {
  Data convertInputToOutput(Data input) => input;
}
