import 'package:api_bloc_base/src/presentation/bloc/base/base_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class Family<Arg, Bloc extends BaseCubit>
    extends Cubit<Map<Arg, Bloc>> {
  Family() : super({});

  Bloc operator [](Arg arg) {
    return getBloc(arg);
  }

  Bloc getBloc(Arg arg) {
    final existingBloc = state[arg];
    if (existingBloc != null && !existingBloc.isClosed) {
      return existingBloc;
    } else {
      final newBloc = createBloc(arg);
      final newMap = Map.of(state);
      newMap.update(arg, (value) {
        if (!value.isClosed) {
          value.close();
        }
        return newBloc;
      }, ifAbsent: () {
        return newBloc;
      });
      emit(newMap);
      return newBloc;
    }
  }

  Bloc createBloc(Arg arg);

  @override
  Future<void> close() async {
    try {
      final futures = state.values.map((bloc) => bloc.close());
      await Future.wait(futures);
    } catch (_) {}
    return super.close();
  }
}

class SimpleFamily<Arg, Bloc extends BaseCubit> extends Family<Arg, Bloc> {
  final Bloc Function(Arg) creator;

  SimpleFamily(this.creator);

  @override
  Bloc createBloc(Arg arg) {
    return creator(arg);
  }
}
