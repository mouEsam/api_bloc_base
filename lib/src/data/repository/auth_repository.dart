import 'dart:async';
import 'package:rxdart/rxdart.dart';

import 'package:api_bloc_base/src/data/model/remote/params/auth_params.dart';
import 'package:api_bloc_base/src/data/model/remote/response/base_api_response.dart';
import 'package:api_bloc_base/src/data/model/remote/response/base_user_response.dart';
import 'package:api_bloc_base/src/data/service/converter.dart';
import 'package:api_bloc_base/src/data/source/local/user_defaults.dart';
import 'package:api_bloc_base/src/data/source/remote/base_rest_client.dart';
import 'package:api_bloc_base/src/domain/entity/_index.dart';
import 'package:dartz/dartz.dart';

import 'base_repository.dart';

abstract class BaseAuthRepository<T extends BaseProfile>
    extends BaseRepository {
  final UserDefaults userDefaults;
  final BaseResponseConverter<BaseUserResponse, T> converter;

  const BaseAuthRepository(this.converter, this.userDefaults);
  String get noAccountSavedInError;

  BaseResponseConverter<BaseUserResponse, T> get refreshConverter => converter;
  BaseResponseConverter<BaseUserResponse, T> get autoLoginConverter =>
      converter;

  RequestResult<BaseUserResponse> internalLogin(BaseAuthParams params);
  RequestResult<BaseUserResponse> internalRefreshToken(T account);
  RequestResult<BaseUserResponse> internalRefreshProfile(T account);
  RequestResult<BaseApiResponse> internalLogout(T account);

  Future<bool> get _wasSaved async {
    return (await userDefaults.signedAccount) != null;
  }

  Result<Either<ResponseEntity, T>> login(BaseAuthParams params) {
    final result = internalLogin(params);
    return handleFullResponse<BaseUserResponse, T>(
      result,
      interceptResult: (result) {
        if (result.active == true && params.rememberMe) {
          saveAccount(result);
        }
        print(result.toJson());
      },
      converter: converter,
    );
  }

  Result<Either<ResponseEntity, T>> autoLogin() {
    return dataRequireUser<T>((savedAccount) {
      final operation = internalRefreshToken(savedAccount);
      final result = handleFullResponse<BaseUserResponse, T>(operation,
          converter: autoLoginConverter);
      return result.resultFuture.then((value) async {
        return value.fold((l) => Left(handleReAuthFailure(l, savedAccount)),
                (r) {
              checkSave(r);
              return Right(r);
            });
      });
    });
  }

  Result<Either<ResponseEntity, T>> refreshToken(T profile) {
    return dataRequireUser<T>((savedAccount) {
      final operation = internalRefreshToken(savedAccount);
      final result = handleFullResponse<BaseUserResponse, T>(operation,
          converter: autoLoginConverter);
      return result.resultFuture.then<Either<ResponseEntity, T>>((value) async {
        return value.fold((l) => Left(handleReAuthFailure(l, savedAccount)),
                (r) {
              checkSave(r);
              return Right(r);
            });
      });
    });
  }

  Result<Either<ResponseEntity, T>> refreshProfile(T profile) {
    return dataRequireUser<T>((savedAccount) {
      final operation = internalRefreshProfile(savedAccount);
      final result = handleFullResponse<BaseUserResponse, T>(operation,
          converter: autoLoginConverter);
      return result.resultFuture.then<Either<ResponseEntity, T>>((value) async {
        return value.fold((l) => Left(handleReAuthFailure(l, savedAccount)),
                (r) {
              checkSave(r);
              return Right(r);
            });
      });
    });
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
      return Success();
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
    return Result(resultFuture: result);
  }

  Result<ResponseEntity> signOut(T account) {
    final result = internalLogout(account);
    return handleApiResponse(result, interceptData: (_) {
      saveAccount(null);
    });
  }

  Future<void> checkSave(T account) async {
    if (account.active == true && await _wasSaved) {
      saveAccount(account);
    }
  }

  Future<void> saveAccount(T? account) {
    final one = userDefaults.setSignedAccount(account);
    final two = userDefaults.setUserToken(account?.accessToken);
    return Future.wait([one, two]);
  }

  Result<ResponseEntity> requireUser(
      FutureOr<ResponseEntity> Function(T user) action) {
    return userDefaults.signedAccount.maybe.result((savedAccount) {
      if (savedAccount is T) {
        return action(savedAccount);
      }
      return NoAccountSavedFailure(noAccountSavedInError);
    });
  }

  Result<D> withUser<D>(
      FutureOr<D> Function(T? user) action) {
    return userDefaults.signedAccount.maybe.result((savedAccount) {
      return action(savedAccount as T?);
    });
  }

  Result<Either<ResponseEntity, D>> dataRequireUser<D>(
      FutureOr<Either<ResponseEntity, D>> Function(T user) action) {
    return userDefaults.signedAccount.maybe.result((savedAccount) {
      if (savedAccount is T) {
        return action(savedAccount);
      }
      return Left(NoAccountSavedFailure(noAccountSavedInError));
    });
  }

  Result<Either<ResponseEntity, D>> dataWithUser<D>(
      FutureOr<Either<ResponseEntity, D>> Function(T? user) action) {
    return withUser(action);
  }
}