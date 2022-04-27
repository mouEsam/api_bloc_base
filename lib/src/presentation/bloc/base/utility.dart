import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:api_bloc_base/src/utils/utils.dart';
import 'package:equatable/equatable.dart';

import 'base_bloc.dart';

class UtilityState extends Equatable {
  final bool isLocked;
  final bool isWorking;

  const UtilityState.initial()
      : isWorking = false,
        isLocked = false;
  const UtilityState(this.isLocked, this.isWorking);

  UtilityState copyWith({
    bool? isLocked,
    bool? isWorking,
  }) {
    return UtilityState(
      isLocked ?? this.isLocked,
      isWorking ?? this.isWorking,
    );
  }

  @override
  List<Object?> get props => [isLocked, isWorking];
}

class _LockListener {
  final Completer<void> completer;
  final bool lockAfter;

  const _LockListener(this.completer, this.lockAfter);
}

abstract class UtilityBloc extends BaseCubit<UtilityState> {
  final Queue<_LockListener> _lockListeners = ListQueue();
  int _workers = 0;

  UtilityBloc() : super(const UtilityState.initial());

  @override
  void stateChanged(nextState) {
    _giveLock(nextState);
  }

  void _giveLock(UtilityState nextState) {
    if (!nextState.isLocked) {
      final listCount = _lockListeners.length;
      for (int i = 0; i < listCount; i++) {
        final listener = _lockListeners.removeFirst();
        listener.completer.complete();
        if (listener.lockAfter) {
          lock();
          break;
        }
      }
    }
  }

  Future<void> awaitFree() => awaitState((i) => !i.isWorking);

  Future<void> awaitLock([bool? lockAfter]) {
    final completer = Completer<void>();
    _lockListeners.add(_LockListener(completer, lockAfter == true));
    _giveLock(state);
    return completer.future;
  }

  bool get isFree => !state.isWorking;
  bool get isWorking => state.isWorking;

  void incrementWorkers([bool? locked]) {
    _workers++;
    _setState(locked);
  }

  void decrementWorkers([bool? locked]) {
    _workers = max(0, _workers - 1);
    _setState(locked);
  }

  void lock() {
    emit(state.copyWith(isLocked: true));
  }

  void unlock() {
    emit(state.copyWith(isLocked: false));
  }

  void _setState([bool? locked]) {
    if (_workers > 0) {
      emit(state.copyWith(isWorking: true, isLocked: locked));
    } else {
      emit(state.copyWith(isWorking: true, isLocked: locked));
    }
  }

  FutureOr<T> wrapAction<T>(
    FutureOr<T> Function() action, {
    bool? isAtomic,
  }) async {
    if (isAtomic == false) {
      isAtomic = null;
    }
    final futures = [awaitLock(isAtomic)];
    if (isAtomic == true) {
      futures.add(awaitFree());
    }
    await Future.wait(futures);
    incrementWorkers(isAtomic);
    late final T result;
    try {
      result = await action();
    } catch (_) {
      result = null as T;
    }
    decrementWorkers(isAtomic.let((isAtomic) => !isAtomic));
    return result;
  }
}
