import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';

class Trigger<Data> extends BaseCubit<Loaded<Data>> {
  Trigger(Data initialState) : super(Loaded(initialState));

  void trigger(Data newData) {
    emit(Loaded(newData));
  }
}
