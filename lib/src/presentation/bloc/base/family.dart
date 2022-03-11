import 'package:api_bloc_base/src/presentation/bloc/base/base_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlocMember<Bloc> {
  final Bloc bloc;
  final Set<FamilyListener> _listeners = {};

  BlocMember._(this.bloc);
}

abstract class FamilyListener {}

mixin FamilyListenerMixin<T extends StatefulWidget> on State<T>
    implements FamilyListener {}

abstract class Family<Arg, Bloc extends BaseCubit>
    extends Cubit<Map<Arg, BlocMember<Bloc>>> {
  Family() : super({});

  Bloc operator [](Arg arg) {
    return getBloc(arg);
  }

  Bloc getBloc(Arg arg, [FamilyListener? listener]) {
    final existingBloc = state[arg];
    if (existingBloc != null && !existingBloc.bloc.isClosed) {
      if (listener != null) existingBloc._listeners.add(listener);
      return existingBloc.bloc;
    } else {
      final newBloc = BlocMember._(createBloc(arg));
      final newMap = Map.of(state);
      newMap.update(arg, (value) {
        final oldBloc = value.bloc;
        if (!oldBloc.isClosed) {
          oldBloc.close();
        }
        return newBloc;
      }, ifAbsent: () {
        return newBloc;
      });
      emit(newMap);
      return newBloc.bloc;
    }
  }

  void clearBloc(Arg arg, [FamilyListener? listener]) {
    final newMap = Map.of(state);
    final existingBloc = state[arg];
    if (existingBloc != null && !existingBloc.bloc.isClosed) {
      if (listener != null) existingBloc._listeners.remove(listener);
      if (existingBloc._listeners.isEmpty) {
        existingBloc.bloc.close();
        newMap.remove(arg);
      }
    }
    emit(newMap);
  }

  Bloc createBloc(Arg arg);

  @override
  Future<void> close() async {
    try {
      final futures = state.values.map((bloc) => bloc.bloc.close());
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
