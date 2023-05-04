import 'package:api_bloc_base/src/data/model/remote/params/base_errors.dart';
import 'package:api_bloc_base/src/domain/entity/base_profile.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

class ResponseEntity extends Equatable {
  final String? message;

  const ResponseEntity(this.message);

  @override
  List<Object?> get props => [message];
}

class Success extends ResponseEntity {
  const Success([String? message = '']) : super(message);

  @override
  List<Object?> get props => [...super.props];
}

class SuccessWithData<D> extends Success {
  final D data;

  const SuccessWithData(this.data, [String? message = '']) : super(message);

  @override
  List<Object?> get props => [...super.props, data];
}

class Failure extends ResponseEntity {
  final BaseErrors? errors;

  const Failure([String? message, this.errors]) : super(message);

  @override
  List<Object?> get props => [...super.props, errors];
}

class ConversionFailure extends Failure {
  final Type convertedType;

  const ConversionFailure(
    String message,
    this.convertedType, {
    BaseErrors? errors,
  }) : super(message, errors);

  @override
  List<Object?> get props => [...super.props, convertedType];
}

class InternetFailure extends Failure {
  final DioError? dioError;
  final Response? response;
  final Failure? baseFailure;

  int? get statusCode => (response ?? dioError?.response)?.statusCode;

  const InternetFailure(
    String message, {
    this.dioError,
    this.response,
    this.baseFailure,
    BaseErrors? errors,
  }) : super(message, errors);

  InternetFailure.dio(
    String message,
    DioError error, {
    this.baseFailure,
    BaseErrors? errors,
  })  : dioError = error,
        response = error.response,
        super(message, errors);

  @override
  List<Object?> get props => [...super.props, dioError, response, baseFailure];
}

class Cancellation extends ResponseEntity {
  const Cancellation() : super(null);

  @override
  List<Object?> get props => [...super.props];
}

class NoAccountSavedFailure extends Failure {
  const NoAccountSavedFailure(
    String message, {
    BaseErrors? errors,
  }) : super(message, errors);

  @override
  List<Object?> get props => [...super.props];
}

class RefreshFailure<T extends BaseProfile<T>> extends Failure {
  final T oldProfile;
  final Failure? baseFailure;

  const RefreshFailure(
    String? message,
    this.oldProfile, {
    this.baseFailure,
    BaseErrors? errors,
  }) : super(message, errors);

  @override
  List<Object?> get props => [...super.props, oldProfile, baseFailure];
}
