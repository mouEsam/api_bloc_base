import 'package:api_bloc_base/src/presentation/bloc/base/base_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TreeMember<Bloc> {
  final Bloc bloc;
  final Set<TreeListener> _listeners = {};

  TreeMember._(this.bloc);
}

class TreeArgKey extends Equatable {
  final TreeListener? _unique;

  const TreeArgKey._(this._unique);

  @override
  get props => [_unique?.key];
}

abstract class TreeListener {
  Key get key;
}

mixin TreeListenerMixin<T extends StatefulWidget> on State<T>
    implements TreeListener {
  Key get key => ValueKey(this);
}

abstract class Tree<Bloc extends Cubit>
    extends Cubit<Map<TreeArgKey, TreeMember<Bloc>>> {
  final bool autoDispose;

  Tree([this.autoDispose = true]) : super({});

  Bloc? operator [](TreeListener? arg) {
    final argKey = TreeArgKey._(arg);
    final existingBloc = state[argKey];
    if (existingBloc != null && !existingBloc.bloc.isClosed) {
      return existingBloc.bloc;
    }
    return null;
  }

  Bloc call(TreeListener listener, {bool? unique}) {
    final argKey = TreeArgKey._(unique == true ? listener : null);
    final existingBloc = state[argKey];
    if (existingBloc != null && !existingBloc.bloc.isClosed) {
      existingBloc._listeners.add(listener);
      return existingBloc.bloc;
    } else {
      final newBloc = TreeMember._(createBloc());
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

  void clear(TreeListener listener, {bool? unique}) {
    final argKey = TreeArgKey._(unique == true ? listener : null);
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

  Bloc createBloc();

  @override
  Future<void> close() async {
    try {
      final futures = state.values.map((bloc) => bloc.bloc.close());
      await Future.wait(futures);
    } catch (_) {}
    return super.close();
  }
}

class SimpleTree<Bloc extends BaseCubit> extends Tree<Bloc> {
  final Bloc Function() creator;

  SimpleTree(this.creator, {bool autoDispose = true}) : super(autoDispose);

  @override
  Bloc createBloc() {
    return creator();
  }
}
