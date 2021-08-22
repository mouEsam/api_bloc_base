import 'package:api_bloc_base/src/data/model/remote/base_errors.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:equatable/equatable.dart';

class BlocState<T> extends Equatable {
  const BlocState();

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [];
}

class LoadingState<T> extends BlocState<T> {}

class ErrorState<T> extends BlocState<T> {
  final String? message;

  const ErrorState(this.message);

  @override
  List<Object?> get props => [this.message];
}

class LoadedState<T> extends BlocState<T> {
  final T data;

  const LoadedState(this.data);

  @override
  List<Object?> get props => [this.data];
}

abstract class Operation {
  String? get operationTag;
}

class OnGoingOperationState<T> extends LoadedState<T> implements Operation {
  final String? operationTag;
  final String? loadingMessage;
  final Stream<double>? progress;

  const OnGoingOperationState(T data,
      {this.loadingMessage, this.operationTag, this.progress})
      : super(data);

  @override
  List<Object?> get props =>
      [...super.props, this.operationTag, this.loadingMessage, this.progress];
}

class FailedOperationState<T> extends LoadedState<T> implements Operation {
  final String? operationTag;
  final Failure? failure;
  final Function()? retry;

  const FailedOperationState(T data,
      {this.operationTag, this.failure, this.retry})
      : super(data);

  FailedOperationState.message(T data,
      {this.operationTag, String? errorMessage, BaseErrors? errors, this.retry})
      : failure = Failure(errorMessage, errors),
        super(data);

  String? get errorMessage => failure?.message;
  BaseErrors? get errors => failure?.errors;

  @override
  List<Object?> get props =>
      [...super.props, this.operationTag, this.failure, this.retry];
}

class SuccessfulOperationState<T> extends LoadedState<T> implements Operation {
  final String? operationTag;
  final String? successMessage;

  const SuccessfulOperationState(T data,
      {this.operationTag, this.successMessage})
      : super(data);

  @override
  List<Object?> get props =>
      [...super.props, this.operationTag, this.successMessage];
}
