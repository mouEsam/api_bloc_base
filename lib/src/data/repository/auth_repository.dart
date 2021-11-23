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
    );
  }

  Result<Either<ResponseEntity, T>> autoLogin() {
    final savedProfile = Future(() async => await userDefaults.signedAccount)
        .catchError((e, s) => null)
        .then<Either<ResponseEntity, T>>((savedAccount) {
      if (savedAccount is T) {
        final operation = internalRefreshToken(savedAccount);
        final result = handleFullResponse<BaseUserResponse, T>(operation,
            converter: converter);
        return result.resultFuture.then((value) async {
          return value
              .fold((l) => Left(RefreshFailure(l.message, savedAccount)), (r) {
            checkSave(r);
            return Right(r);
          });
        });
      }
      return Left(NoAccountSavedFailure(noAccountSavedInError));
    });
    return Result(resultFuture: savedProfile);
  }

  Result<Either<ResponseEntity, T>> refreshToken(T profile) {
    final operation = internalRefreshToken(profile);
    final result = handleFullResponse<BaseUserResponse, T>(operation,
        converter: converter);
    final future =
        result.resultFuture.then<Either<ResponseEntity, T>>((value) async {
      return value.fold((l) => Left(RefreshFailure(l.message, profile)), (r) {
        checkSave(r);
        return Right(r);
      });
    });
    return Result(resultFuture: future);
  }

  Result<Either<ResponseEntity, T>> refreshProfile(T profile) {
    final operation = internalRefreshProfile(profile);
    final result = handleFullResponse<BaseUserResponse, T>(operation,
        converter: refreshConverter);
    final future =
        result.resultFuture.then<Either<ResponseEntity, T>>((value) async {
      return value.fold((l) => Left(RefreshFailure(l.message, profile)), (r) {
        r = r.updateToken(profile.userToken) as T;
        checkSave(r);
        return Right(r);
      });
    });
    return Result(resultFuture: future);
  }

  Result<ResponseEntity> saveProfileIfRemembered(T profile) {
    final Future<ResponseEntity> savedProfile =
        _wasSaved.then<ResponseEntity>((wasSaved) async {
      if (wasSaved) {
        if (profile.active == true) {
          saveAccount(profile);
        }
      }
      return Success();
    }).catchError((e, s) => NoAccountSavedFailure(noAccountSavedInError));
    return Result(resultFuture: savedProfile);
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
    final wasSaved = await _wasSaved;
    if (account.active == true && wasSaved) {
      saveAccount(account);
    }
  }

  Future<void> saveAccount(T? account) {
    final one = userDefaults.setSignedAccount(account);
    final two = userDefaults.setUserToken(account?.accessToken);
    return Future.wait([one, two]);
  }
}
