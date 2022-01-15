import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';

import 'state.dart';

class Trigger<Data> extends BaseCubit<ProviderLoaded<Data>> {

  final Data initialState;

  Trigger(Data initialData, [Data? noData]) : initialState = noData ?? initialData, super(ProviderLoaded(initialData));


  Data get lastTrigger => state.data;

  void trigger(Data newData) {
    emit(ProviderLoaded(newData));
  }
}
