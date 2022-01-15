import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';

import 'state.dart';

class Trigger<Data> extends BaseCubit<ProviderLoaded<Data>> {
  Trigger(Data initialState) : super(ProviderLoaded(initialState));

  void trigger(Data newData) {
    emit(ProviderLoaded(newData));
  }
}
