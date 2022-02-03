import 'package:api_bloc_base/src/presentation/bloc/base/state.dart';
import 'package:flutter/foundation.dart';

class Work {
  BlocState _state;

  BlocState get state =>
      cancellationState._isCancelled ? throw CancellationError() : _state;

  set state(BlocState state) {
    _state = state;
  }

  final CancellationState cancellationState;

  Work._(this._state, this.cancellationState);
  Work.start(this._state, [VoidCallback? onCancelled])
      : cancellationState = CancellationState._(onCancelled);

  void cancel() {
    cancellationState.cancel();
  }

  bool get isCancelled => cancellationState._isCancelled;

  Work changeState(BlocState state) {
    this.state = state;
    return this;
  }
}

class CancellationState {
  final VoidCallback? onCancelled;
  bool _isCancelled;

  CancellationState._(this.onCancelled, [this._isCancelled = false]);

  void cancel() {
    if (!_isCancelled) {
      _isCancelled = true;
      onCancelled?.call();
    }
  }
}

class CancellationError implements Exception {}
