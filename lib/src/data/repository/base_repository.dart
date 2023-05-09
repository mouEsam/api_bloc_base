import 'dart:async';

import 'package:api_bloc_base/src/data/_index.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:dartz/dartz.dart' as z;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class RequestConversionOperation<T extends BaseApiResponse, S> {
  final RequestResult<T> result;
  BaseResponseConverter<T, S>? converter;
  void Function(T)? interceptData;
  void Function(S)? interceptResult;
  void Function(ResponseEntity)? interceptFailure;
  FutureOr<S> Function(S data)? dataConverter;
  FutureOr<S> Function(ResponseEntity failure)? failureRecovery;

  RequestConversionOperation(this.result, {
    this.converter,
    this.interceptData,
    this.interceptResult,
    this.interceptFailure,
    this.dataConverter,
    this.failureRecovery,
  });
}

abstract class BaseRepository {
  const BaseRepository();

  BaseResponseConverter get converter;

  String get defaultError => 'Error';

  String get internetError => 'Internet Error';

  Result<z.Either<ResponseEntity, S>>
  handleResponseOperation<T extends BaseApiResponse, S>(
      RequestConversionOperation<T, S> operation,) {
    return handleFullResponse<T, S>(
      operation.result,
      converter: operation.converter,
      interceptData: operation.interceptData,
      interceptResult: operation.interceptResult,
      interceptFailure: operation.interceptFailure,
      dataConverter: operation.dataConverter,
      failureRecovery: operation.failureRecovery,
    );
  }

  Result<z.Either<ResponseEntity, S>>
  handleFullResponse<T extends BaseApiResponse, S>(RequestResult<T> result, {
    BaseResponseConverter<T, S>? converter,
    void Function(T)? interceptData,
    void Function(S)? interceptResult,
    void Function(ResponseEntity)? interceptFailure,
    FutureOr<S> Function(S data)? dataConverter,
    FutureOr<S> Function(ResponseEntity failure)? failureRecovery,
  }) {
    final converter_ = converter ??
        (this.converter as BaseResponseConverter<BaseApiResponse, S>);
    final cancelToken = result.cancelToken;
    final future = Future.value(result.value)
        .then<z.Either<ResponseEntity, S>>((value) async {
      final data = value.data;
      S? result;
      late ResponseEntity responseEntity;
      if (data != null) {
        if (converter_.hasData(data)) {
          try {
            interceptData?.call(data);
            result = converter_.convert(data);
          } catch (e, s) {
            debugPrint("$e");
            debugPrint("$s");
            responseEntity = ConversionFailure(
              defaultError,
              data.runtimeType,
            );
          }
        } else {
          responseEntity = converter_.response(data)!;
        }
      } else {
        responseEntity = InternetFailure(defaultError, response: value);
      }
      if (result == null && failureRecovery != null) {
        result = await failureRecovery(responseEntity);
      }
      if (result != null) {
        if (dataConverter != null) {
          try {
            result = await dataConverter(result);
          } catch (e, s) {
            debugPrint("$e");
            debugPrint("$s");
            return z.Left<ResponseEntity, S>(
              ConversionFailure(
                defaultError,
                result.runtimeType,
              ),
            );
          }
        }
        return z.Right<ResponseEntity, S>(result!);
      } else {
        debugPrint(data.runtimeType.toString());
        debugPrint("$data");
        return z.Left<ResponseEntity, S>(responseEntity);
      }
    }).catchError((e, s) async {
      debugPrint("Exception caught");
      debugPrint("$e");
      debugPrint("$s");
      final ResponseEntity failure = _extractFailure(e, converter_);
      if (failureRecovery != null) {
        final result = await failureRecovery(failure);
        if (result != null) {
          return z.Right<ResponseEntity, S>(result);
        }
      }
      return z.Left<ResponseEntity, S>(failure);
    }).then((value) {
      if (interceptFailure != null || interceptResult != null) {
        value.fold((l) {
          interceptFailure?.call(l);
        }, (r) {
          interceptResult?.call(r);
        });
      }
      return value;
    });
    return Result<z.Either<ResponseEntity, S>>(
      cancelToken: cancelToken,
      value: future,
      progress: result.progress,
    );
  }

  Result<ResponseEntity> handleApiResponse<T extends BaseApiResponse>(
      RequestResult<T> result, {
        BaseResponseConverter? converter,
        void Function(T)? interceptData,
        void Function(ResponseEntity)? interceptResult,
      }) {
    final converter_ = converter ?? this.converter;
    final cancelToken = result.cancelToken;
    final future =
    Future.value(result.value).then<ResponseEntity>((value) async {
      final data = value.data!;
      interceptData?.call(data);
      return converter_.response(data)!;
    }).catchError((e, s) async {
      debugPrint("Exception caught");
      debugPrint("$e");
      debugPrint("$s");
      return _extractFailure(e, converter_);
    }).then((value) {
      interceptResult?.call(value);
      return value;
    });
    return Result<ResponseEntity>(
      cancelToken: cancelToken,
      value: future,
      progress: result.progress,
    );
  }

  Result<z.Either<ResponseEntity, S>> handleOperation<S>(
      RequestResult<S> result, {
        void Function(S)? interceptResult,
        void Function(ResponseEntity)? interceptFailure,
      }) {
    final cancelToken = result.cancelToken;
    final future = Future.value(result.value)
        .then<z.Either<ResponseEntity, S>>((value) async {
      final data = value.data!;
      return z.Right<ResponseEntity, S>(data);
    }).catchError((e, s) async {
      debugPrint("Exception caught");
      debugPrint("$e");
      debugPrint("$s");
      final ResponseEntity failure = _extractFailure(e);
      return z.Left<ResponseEntity, S>(failure);
    }).then((value) {
      if (interceptFailure != null || interceptResult != null) {
        value.fold((l) {
          interceptFailure?.call(l);
        }, (r) {
          interceptResult?.call(r);
        });
      }
      return value;
    });
    return Result<z.Either<ResponseEntity, S>>(
      cancelToken: cancelToken,
      value: future,
      progress: result.progress,
    );
  }

  ResponseEntity _extractFailure(e, [
    BaseResponseConverter? converter,
  ]) {
    ResponseEntity? failure;
    if (e is DioError) {
      if (e.type == DioErrorType.cancel) {
        failure = const Cancellation();
      } else if ([
        DioErrorType.receiveTimeout,
        DioErrorType.connectTimeout,
        DioErrorType.sendTimeout,
        DioErrorType.other,
      ].contains(e.type)) {
        failure = null;
      } else {
        final data = e.response?.data;
        if (converter != null && data is BaseApiResponse) {
          failure = converter.response(data);
        }
        failure ??= UnknownFailure(e, defaultError);
      }

      if (failure == null || failure is Failure) {
        failure = InternetFailure.dio(
          failure?.message ?? internetError,
          e,
          errors: failure is Failure ? failure.errors : null,
          baseFailure: failure is Failure ? failure : null,
        );
      }
    }
    return failure ?? UnknownFailure(e, defaultError);
  }

  FutureOr<z.Either<Failure, T>> tryWork<T>(FutureOr<T> Function() work, [
    String? customErrorIfNoMessage,
    Failure Function(String message)? createFailure,
  ]) {
    try {
      final workSync = work();
      if (workSync is Future<T>) {
        final Future<T> workAsync = workSync;
        return workAsync
            .then<z.Either<Failure, T>>((value) => z.Right<Failure, T>(value))
            .catchError((e, s) {
          debugPrint("Exception caught");
          debugPrint("$e");
          debugPrint("$s");
          return handleError<T>(
            e,
            createFailure: createFailure,
            customErrorIfNoMessage: customErrorIfNoMessage,
          );
        });
      } else {
        final T result = workSync;
        return z.Right(result);
      }
    } catch (e, s) {
      debugPrint("$e");
      debugPrint("$s");
      return handleError<T>(
        e,
        createFailure: createFailure,
        customErrorIfNoMessage: customErrorIfNoMessage,
      );
    }
  }

  z.Left<Failure, T> handleError<T>(dynamic error, {
    String? customErrorIfNoMessage,
    Failure Function(String message)? createFailure,
  }) {
    final String? message = getErrorMessage(error, customErrorIfNoMessage);
    createFailure ??= (message) => Failure(message);
    return z.Left(createFailure(message!));
  }

  FutureOr<ResponseEntity> tryWorkWithResponse(FutureOr Function() work, [
    String? customErrorIfNoMessage,
  ]) async {
    try {
      await work();
      return const Success();
    } catch (e, s) {
      debugPrint("$e");
      debugPrint("$s");
      return Failure(getErrorMessage(e, customErrorIfNoMessage));
    }
  }

  String? getErrorMessage(dynamic error, [String? customErrorIfNoMessage]) {
    String? message;
    try {
      message = error.response as String;
    } catch (e, s) {
      message ??= customErrorIfNoMessage ?? defaultError;
    }
    return message;
  }
}
