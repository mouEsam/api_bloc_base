import 'package:equatable/equatable.dart';

abstract class ActionState extends Equatable {
  const ActionState();
  @override
  get props => [];
}

class NoActionState extends ActionState {
  const NoActionState() : super();
}

abstract class ActionDoneState extends ActionState {
  const ActionDoneState() : super();
}

class SimpleActionDoneState<R> extends ActionDoneState {
  final R? result;
  const SimpleActionDoneState([this.result]) : super();
  @override
  get props => [result];
}

abstract class NavigationActionState<S extends ActionDoneState, R>
    extends ActionState {
  final String routeName;
  dynamic get args => null;
  final bool Function(S) doneState;
  final R? Function(S) extractResult;

  final bool returnWhenDone;

  const NavigationActionState(
    this.routeName,
    this.doneState,
    this.extractResult, {
    this.returnWhenDone = true,
  }) : super();
  @override
  get props => [routeName, args, doneState, extractResult, returnWhenDone];
}
