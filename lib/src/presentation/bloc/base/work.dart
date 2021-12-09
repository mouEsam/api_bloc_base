import 'package:api_bloc_base/src/presentation/bloc/base/state.dart';

class Work {
  BlocState state;
  final CancellationState cancellationState;

  Work._(this.state, this.cancellationState);
  Work.start(this.state) : cancellationState = CancellationState._();

  void cancel() {
    cancellationState._isCancelled = true;
  }

  bool get isCancelled => cancellationState._isCancelled;

  Work changeState(BlocState state) {
    this.state = state;
    return this;
  }
}

class CancellationState {
  bool _isCancelled;

  CancellationState._([this._isCancelled = false]);
}
