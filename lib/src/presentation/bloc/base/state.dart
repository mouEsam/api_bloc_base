import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:equatable/equatable.dart';

abstract class BlocState extends Equatable {
  const BlocState();

  @override
  get props => [];
}

class Initial extends BlocState {
  const Initial();
}

class Loading extends BlocState {
  const Loading();
}

class Loaded<T> extends BlocState {
  final T data;

  const Loaded(this.data);

  @override
  get props => [data];
}

abstract class UrgentState implements BlocState {
  bool get isUrgent;
}

mixin UrgentStateMixin on BlocState implements UrgentState {
  bool get isUrgent => true;
}

class Error extends BlocState {
  final ResponseEntity response;

  const Error(this.response);

  @override
  get props => [response];
}

class UrgentError extends Error with UrgentStateMixin {
  const UrgentError(ResponseEntity response) : super(response);
}
