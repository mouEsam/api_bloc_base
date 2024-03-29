import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:api_bloc_base/src/data/model/remote/params/base_errors.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

import '../base/state.dart';

class WorkerState<T> extends Equatable implements BlocState {
  const WorkerState();

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [];
}

class LoadingState<T> extends WorkerState<T> implements Loading {}

class ErrorState<T> extends WorkerState<T> implements Error {
  final ResponseEntity response;

  String? get message => response.message;

  const ErrorState(this.response);

  @override
  List<Object?> get props => [this.response];
}

class LoadedState<T> extends WorkerState<T> implements Loaded<T> {
  final T data;

  const LoadedState(this.data);

  @override
  List<Object?> get props => [this.data];
}

abstract class Operation implements UrgentState {
  String get operationTag;

  bool get silent;
}

mixin OperationMixin on BlocState implements Operation, UrgentStateMixin {
  bool get isUrgent => true;
}

class OnGoingOperationState<T> extends LoadedState<T> with OperationMixin {
  final String? loadingMessage;
  final CancelToken? token;
  final Stream<double>? progress;
  final String operationTag;
  final bool silent;

  const OnGoingOperationState(T data,
      {required this.silent,
      required this.operationTag,
      this.loadingMessage,
      this.token,
      this.progress})
      : super(data);

  bool get isCancellable =>
      token != null &&
      (token is! ChainedCancelToken ||
          (token as ChainedCancelToken).isCancellable);

  void cancel() => token?.cancel();

  @override
  List<Object?> get props => [
        ...super.props,
        this.operationTag,
        this.loadingMessage,
        this.token,
        this.progress,
        this.silent
      ];
}

class FailedOperationState<T> extends LoadedState<T> with OperationMixin {
  final String operationTag;
  final Failure? failure;
  final Function()? retry;
  final bool silent;

  const FailedOperationState(
    T data, {
    required this.operationTag,
    required this.silent,
    this.failure,
    this.retry,
  }) : super(data);

  FailedOperationState.message(
    T data, {
    required this.operationTag,
    required this.silent,
    String? errorMessage,
    BaseErrors? errors,
    this.retry,
  })  : failure = Failure(errorMessage, errors),
        super(data);

  String? get message {
    final errors =
        failure?.errors?.errors.values.expand((element) => element).toList();
    if (errors != null && errors.isNotEmpty) {
      return errors.first;
    } else {
      return failure?.message;
    }
  }

  String? get errorMessage => failure?.message;

  BaseErrors? get errors => failure?.errors;

  @override
  List<Object?> get props => [
        ...super.props,
        this.operationTag,
        this.failure,
        this.retry,
        this.silent,
      ];
}

class SuccessfulOperationState<T> extends LoadedState<T> with OperationMixin {
  final String operationTag;
  final Success success;
  final bool silent;

  const SuccessfulOperationState(
    T data, {
    required this.operationTag,
    required this.silent,
    required this.success,
  }) : super(data);

  SuccessfulOperationState.message(
    T data, {
    required this.operationTag,
    required this.silent,
    String? successMessage,
  })  : success = Success(successMessage),
        super(data);

  String? get successMessage => success.message;

  @override
  List<Object?> get props => [
        ...super.props,
        this.operationTag,
        this.success,
        this.silent,
      ];
}
