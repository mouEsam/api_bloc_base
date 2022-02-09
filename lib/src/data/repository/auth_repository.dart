import 'dart:async';

import 'package:api_bloc_base/src/data/_index.dart';
import 'package:api_bloc_base/src/domain/entity/_index.dart';
import 'package:dartz/dartz.dart';

import 'user_tools.dart';


abstract class BaseAuthRepository<T extends BaseProfile<T>>
    extends BaseRepository with UserProfileUtilsMixin<T> {
  final UserDefaults userDefaults;
  final BaseResponseConverter<BaseUserResponse, T> converter;

  const BaseAuthRepository(this.converter, this.userDefaults);

  BaseResponseConverter<BaseUserResponse, T> get refreshConverter => converter;
  BaseResponseConverter<BaseUserResponse, T> get autoLoginConverter =>
      converter;

  RequestConversionOperation<BaseUserResponse, T> internalLogin(
      BaseAuthParams params);
  RequestConversionOperation<BaseUserResponse, T> internalRefreshToken(
      T account);
  RequestConversionOperation<BaseUserResponse, T> internalRefreshProfile(
      T account);
  RequestResult<BaseApiResponse> internalLogout(T account);

  Result<Either<ResponseEntity, T>> login(BaseAuthParams params) {
    final operation = internalLogin(params);
    final result = operation.result;
    operation.converter ??= converter;
    operation.interceptResult = (user) {
      operation.interceptResult?.call(user);
      if (user.active == true && params.rememberMe) {
        saveAccount(user);
      }
    };
    return handleResponseOperation<BaseUserResponse, T>(operation);
  }

  Result<Either<ResponseEntity, T>> autoLogin() {
    return dataRequireUser<T>((savedAccount) {
      final operation = internalRefreshToken(savedAccount);
      operation.converter ??= autoLoginConverter;
      operation.interceptResult = (user) {
        operation.interceptResult?.call(user);
        checkSave(user);
      };
      final result = handleResponseOperation<BaseUserResponse, T>(operation);
      return result.next((value) =>
          value.leftMap((l) => handleReAuthFailure(l, savedAccount)));
    });
  }

  Result<Either<ResponseEntity, T>> refreshToken(T profile) {
    final operation = internalRefreshToken(profile);
    operation.converter ??= autoLoginConverter;
    operation.interceptResult = (user) {
      operation.interceptResult?.call(user);
      checkSave(user);
    };
    final result = handleResponseOperation<BaseUserResponse, T>(operation);
    return result.next(
      (value) => value.leftMap((l) => handleReAuthFailure(l, profile)),
    );
  }

  Result<Either<ResponseEntity, T>> refreshProfile(T profile) {
    final operation = internalRefreshProfile(profile);
    operation.converter ??= refreshConverter;
    operation.dataConverter ??= (r) => r.updateToken(
          profile.userToken,
        );
    final result = handleResponseOperation(operation);
    return result.next(
      (value) => value.leftMap((l) => handleReAuthFailure(l, profile)),
    );
  }

  ResponseEntity handleReAuthFailure(ResponseEntity responseEntity,
      [T? oldAccount]) {
    if (oldAccount != null) {
      return RefreshFailure(responseEntity.message, oldAccount);
    } else {
      return responseEntity;
    }
  }

  Result<ResponseEntity> saveProfileIfRemembered(T profile) {
    return requireUser((user) {
      if (profile.active) {
        saveAccount(profile);
      }
      return Success().asResult;
    });
  }

  Result<ResponseEntity> offlineSignOut() {
    final result = saveAccount(null).then<ResponseEntity>((value) {
      return Success();
    }).catchError((e, s) {
      print(e);
      print(s);
      return Failure(e.response);
    });
    return result.asResult;
  }

  Result<ResponseEntity> signOut(T account) {
    final operation = internalLogout(account);
    return handleApiResponse(
      operation,
      interceptData: (_) {
        saveAccount(null);
      },
    );
  }


}
