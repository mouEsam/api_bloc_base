import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';

class Trigger<Data> extends BaseCubit<Loaded<Data>> {
  final Data initialState;

  Trigger(Data initialData, [Data? noData])
      : initialState = noData ?? initialData,
        super(Loaded(initialData));

  Data get lastTrigger => state.data;

  void trigger(Data newData) {
    emit(Loaded(newData));
  }
}
