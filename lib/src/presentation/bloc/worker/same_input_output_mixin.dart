import 'listener_bloc.dart';

mixin SameInputOutputMixin<Data> on ListenerBloc<Data, Data> {
  Data convertInputToOutput(Data input) => input;
}
