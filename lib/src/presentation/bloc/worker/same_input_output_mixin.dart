import 'package:api_bloc_base/src/presentation/bloc/base/input_to_output.dart';

mixin SameInputOutputMixin<Data, State> on InputToOutput<Data, Data, State> {
  Data convertInputToOutput(Data input) => input;
}
