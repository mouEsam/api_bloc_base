import 'package:api_bloc_base/src/presentation/bloc/base/input_to_output.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/state.dart';

mixin SameInputOutputMixin<Data, State extends BlocState>
    on InputToOutput<Data, Data, State> {
  Data convertInputToOutput(Data input) => input;
}
