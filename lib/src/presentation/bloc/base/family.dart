import 'package:api_bloc_base/src/presentation/bloc/base/base_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FamilyMember<Bloc> {
  final Bloc bloc;
  final Set<FamilyListener> _listeners = {};

  FamilyMember._(this.bloc);
}

class FamilyArgKey<Arg> extends Equatable {
  final Arg arg;
  final FamilyListener? _unique;

  const FamilyArgKey._(this.arg, this._unique);

  @override
  get props => [arg, _unique?.key];
}

abstract class FamilyListener {
  Key get key;
}

mixin FamilyListenerMixin<T extends StatefulWidget> on State<T>
    implements FamilyListener {
  Key get key => ValueKey(this);
}

abstract class Family<Arg, Bloc extends Cubit>
    extends Cubit<Map<FamilyArgKey<Arg>, FamilyMember<Bloc>>> {
  final bool autoDispose;

  Family([this.autoDispose = true]) : super({});

  Bloc? operator [](Arg arg) {
    return get(arg);
  }

  Bloc? get(Arg arg, {FamilyListener? listener}) {
    final argKey = FamilyArgKey._(arg, listener);
    final existingBloc = state[argKey];
    if (existingBloc != null && !existingBloc.bloc.isClosed) {
      return existingBloc.bloc;
    }
    return null;
  }

  Bloc call(Arg arg, FamilyListener listener, {bool? unique}) {
    final argKey = FamilyArgKey._(arg, unique == true ? listener : null);
    final existingBloc = state[argKey];
    if (existingBloc != null && !existingBloc.bloc.isClosed) {
      existingBloc._listeners.add(listener);
      return existingBloc.bloc;
    } else {
      final newBloc = FamilyMember._(createBloc(arg));
      final newMap = Map.of(state);
      newMap.update(argKey, (value) {
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

  void clear(Arg arg, FamilyListener listener, {bool? unique}) {
    final argKey = FamilyArgKey._(arg, unique == true ? listener : null);
    final newMap = Map.of(state);
    final existingBloc = state[argKey];
    if (existingBloc != null && !existingBloc.bloc.isClosed) {
      existingBloc._listeners.remove(listener);
      if (autoDispose && existingBloc._listeners.isEmpty) {
        existingBloc.bloc.close();
        newMap.remove(argKey);
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

  SimpleFamily(this.creator, {bool autoDispose = true}) : super(autoDispose);

  @override
  Bloc createBloc(Arg arg) {
    return creator(arg);
  }
}
