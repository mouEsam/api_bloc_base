import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';

class SignalEmitter<Data> extends BaseCubit<Loaded<Data>> {
  final Data noSignal;

  SignalEmitter(Data initialSignal, [Data? noSignal])
      : noSignal = noSignal ?? initialSignal,
        super(Loaded(initialSignal));

  Data get lastSignal => state.data;

  void signal(Data newData) {
    emit(Loaded(newData));
  }
}
