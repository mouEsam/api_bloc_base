import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';

import 'state.dart';

class SignalEmitter<Data> extends BaseCubit<ProviderLoaded<Data>> {

  final Data noSignal;

  SignalEmitter(Data initialSignal, [Data? noSignal]) : noSignal = noSignal ?? initialSignal, super(ProviderLoaded(initialSignal));

  Data get lastSignal => state.data;

  void signal(Data newData) {
    emit(ProviderLoaded(newData));
  }
}
