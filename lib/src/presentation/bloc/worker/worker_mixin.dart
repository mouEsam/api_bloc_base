import 'dart:async';

import 'package:api_bloc_base/src/data/_index.dart';
import 'package:api_bloc_base/src/domain/entity/entity.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/utils/_index.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../base/state.dart';
import '_defs.dart';
import 'worker_state.dart';

class _Work {
  final String loadingMessage;
  final CancelToken? cancelToken;
  final Stream<double>? progress;
  final bool announceLoading;
  final bool emitLoading;

  const _Work(this.loadingMessage, this.cancelToken, this.progress,
      this.emitLoading, this.announceLoading);
}

mixin WorkerMixin<Output>
    on StatefulWorkerBloc<Output>, TrafficLightsWorkerMixin<Output> {
  static const _DEFAULT_OPERATION = '_DEFAULT_OPERATION';
  final ValueNotifier<bool> _isNotOperation = ValueNotifier(true);

  String get loading => 'loading';

  Output get currentData;

  Map<String, _Work> _operationStack = {};

  @override
  get trafficLights => super.trafficLights..add(_isNotOperation);

  @override
  get notifiers => super.notifiers..add(_isNotOperation);

  Box<BlocState> _nextState = Box();
  void emitState(BlocState state) {
    if (state is Operation || lastTrafficLightsValue) {
      if (state is WorkerState<Output>) {
        emit(state);
      } else if (state is Loading) {
        emitLoading();
      } else if (state is Loaded<Output>) {
        emitData(state.data);
      } else if (state is Error) {
        emitError(state.response);
      }
    } else {
      if (!_nextState.hasData) {
        whenActive(() {
          emitState(_nextState.data);
        });
      }
      _nextState.data = state;
    }
  }

  void emitData(Output event);

  void emitCurrent() {
    emitLoaded(currentData);
  }

  void interceptOperation<S>(Result<Either<ResponseEntity, S>> result,
      {void onSuccess()?, void onFailure()?, void onDate(S data)?}) {
    Future.value(result.value).then((value) {
      value.fold((l) {
        if (l is Success) {
          onSuccess?.call();
        } else if (l is Failure) {
          onFailure?.call();
        }
      }, (r) {
        onSuccess?.call();
        onDate?.call(r);
      });
    });
  }

  void interceptResponse(Result<ResponseEntity> result,
      {void onSuccess()?, void onFailure()?}) {
    Future.value(result.value).then((value) {
      if (value is Success) {
        onSuccess?.call();
      } else if (value is Failure) {
        onFailure?.call();
      }
    });
  }

  void checkOperations() {
    final hasOperations = _operationStack.isNotEmpty;
    _isNotOperation.value = !hasOperations;
    if (hasOperations && state is! OnGoingOperationState) {
      final item = _operationStack.entries.first;
      if (item.value.emitLoading) {
        emit(OnGoingOperationState(
          currentData,
          loadingMessage: item.value.loadingMessage,
          operationTag: item.key,
          progress: item.value.progress,
          token: item.value.cancelToken,
          silent: !item.value.announceLoading,
        ));
      }
    }
  }

  Future<T?> handleDataOperation<T extends Entity>(
      Result<Either<ResponseEntity, T>> result,
      {String? loadingMessage,
      String? successMessage,
      bool announceFailure = true,
      bool announceSuccess = true,
      bool announceLoading = true,
      bool emitFailure = true,
      bool emitSuccess = true,
      bool emitLoading = true,
      String operationTag = _DEFAULT_OPERATION,
      bool Function(ResponseEntity response, String tag)?
          handleResponse}) async {
    startOperation(loadingMessage,
        cancelToken: result.cancelToken,
        progress: result.progress,
        emitLoading: emitLoading,
        announceLoading: announceLoading,
        operationTag: operationTag);
    final future = await result.value;
    return future.fold<T?>(
      (l) {
        bool? handled = handleResponse?.call(l, operationTag);
        if (handled == true) {
          removeOperation(operationTag: operationTag);
        } else {
          this.handleResponse(l,
              announceFailure: announceFailure,
              announceSuccess: announceSuccess,
              emitFailure: emitFailure,
              emitSuccess: emitSuccess,
              operationTag: operationTag);
        }
        return null;
      },
      (r) {
        successfulOperation(
          successMessage,
          emitSuccess: emitSuccess,
          announceSuccess: announceSuccess,
          operationTag: operationTag,
        );
        return r;
      },
    );
  }

  Future<Operation?> handleOperation(Result<ResponseEntity> result,
      {String? loadingMessage,
      String? successMessage,
      bool announceLoading = true,
      bool announceFailure = true,
      bool emitFailure = true,
      bool announceSuccess = true,
      bool emitSuccess = true,
      String operationTag = _DEFAULT_OPERATION}) async {
    startOperation(loadingMessage,
        cancelToken: result.cancelToken,
        progress: result.progress,
        announceLoading: announceLoading,
        emitLoading: emitFailure || emitSuccess,
        operationTag: operationTag);
    final future = await result.value;
    return handleResponse(future,
        announceFailure: announceFailure,
        emitFailure: emitFailure,
        announceSuccess: announceSuccess,
        emitSuccess: emitSuccess,
        operationTag: operationTag);
  }

  Operation? handleResponse(
    ResponseEntity l, {
    String operationTag = _DEFAULT_OPERATION,
    Function()? retry,
    bool announceFailure = true,
    bool emitFailure = true,
    bool announceSuccess = true,
    bool emitSuccess = true,
  }) {
    if (l is Failure) {
      return failedOperation(l,
          announceFailure: announceFailure,
          emitFailure: emitFailure,
          retry: retry,
          operationTag: operationTag);
    } else if (l is Success) {
      return successfulOperation(l.message,
          announceSuccess: announceSuccess,
          emitSuccess: emitSuccess,
          operationTag: operationTag);
    } else {
      removeOperation(operationTag: operationTag);
    }
    return null;
  }

  void startOperation(String? message,
      {CancelToken? cancelToken,
      Stream<double>? progress,
      bool announceLoading = true,
      bool emitLoading = true,
      String operationTag = _DEFAULT_OPERATION}) {
    message ??= loading;
    print(announceLoading);
    print("operationTag");
    _operationStack[operationTag] = _Work(
      message,
      cancelToken,
      progress,
      emitLoading,
      announceLoading,
    );
    checkOperations();
  }

  void cancelOperation({String operationTag = _DEFAULT_OPERATION}) {
    emitCurrent();
    final tuple = _operationStack.remove(operationTag)!;
    if (tuple.cancelToken?.isCancelled == false) {
      tuple.cancelToken!.cancel();
    }
    checkOperations();
  }

  void removeOperation({String operationTag = _DEFAULT_OPERATION}) {
    _operationStack.remove(operationTag);
    emitCurrent();
    checkOperations();
  }

  Operation successfulOperation(String? message,
      {bool announceSuccess = true,
      bool emitSuccess = true,
      String operationTag = _DEFAULT_OPERATION}) {
    final op = SuccessfulOperationState(currentData,
        silent: !announceSuccess,
        successMessage: message,
        operationTag: operationTag);
    if (emitSuccess) emit(op);
    _operationStack.remove(operationTag);
    checkOperations();
    return op;
  }

  FailedOperationState failedOperationMessage(String? message,
      {bool announceFailure = true,
      bool emitFailure = true,
      BaseErrors? errors,
      Function()? retry,
      String operationTag = _DEFAULT_OPERATION}) {
    final op = FailedOperationState.message(currentData,
        errorMessage: message,
        operationTag: operationTag,
        retry: retry,
        silent: !announceFailure,
        errors: errors);
    return _failedOperation(op,
        emitFailure: emitFailure, operationTag: operationTag);
  }

  FailedOperationState failedOperation(Failure? failure,
      {bool announceFailure = true,
      bool emitFailure = true,
      Function()? retry,
      String operationTag = _DEFAULT_OPERATION}) {
    final op = FailedOperationState(currentData,
        silent: !announceFailure,
        failure: failure,
        operationTag: operationTag,
        retry: retry);
    return _failedOperation(op,
        emitFailure: emitFailure, operationTag: operationTag);
  }

  FailedOperationState _failedOperation(FailedOperationState<Output> op,
      {bool emitFailure = true, String operationTag = _DEFAULT_OPERATION}) {
    if (emitFailure) emit(op);
    _operationStack.remove(operationTag);
    checkOperations();
    return op;
  }
}
