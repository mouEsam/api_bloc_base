import 'package:api_bloc_base/src/data/_index.dart';
import 'package:api_bloc_base/src/domain/entity/_index.dart';
import 'package:dartz/dartz.dart';

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

  RequestConversionOperation<BaseUserResponse, T>? internalRefreshToken(
      T account);

  RequestConversionOperation<BaseUserResponse, T>? internalRefreshProfile(
      T account);

  RequestResult<BaseApiResponse>? internalLogout(T account);

  Result<Either<ResponseEntity, T>> login(BaseAuthParams params) {
    final operation = internalLogin(params);
    operation.converter ??= converter;
    final _intercept = operation.interceptResult;
    operation.interceptResult = (user) {
      _intercept?.call(user);
      if (user.active == true && params.rememberMe) {
        saveAccount(user);
      } else {
        saveAccount(null);
      }
    };
    return handleResponseOperation<BaseUserResponse, T>(operation);
  }

  Result<Either<ResponseEntity, T>> autoLogin() {
    return dataRequireUser<T>((savedAccount) {
      final operation = internalRefreshToken(savedAccount);
      if (operation != null) {
        operation.converter ??= autoLoginConverter;
        final _intercept = operation.interceptResult;
        operation.interceptResult = (user) {
          _intercept?.call(user);
          overwriteSavedAccount(user);
        };
        final result = handleResponseOperation<BaseUserResponse, T>(operation);
        return result.next(
          (value) => value.leftMap((l) => handleReAuthFailure(l, savedAccount)),
        );
      }
      return Result(value: Right(savedAccount));
    });
  }

  Result<Either<ResponseEntity, T>> refreshToken(T profile) {
    final operation = internalRefreshToken(profile);
    if (operation != null) {
      operation.converter ??= autoLoginConverter;
      final intercept_ = operation.interceptResult;
      operation.interceptResult = (user) {
        intercept_?.call(user);
        overwriteSavedAccount(user);
      };
      final result = handleResponseOperation<BaseUserResponse, T>(operation);
      return result.next(
        (value) => value.leftMap((l) => handleReAuthFailure(l, profile)),
      );
    }
    return Result(value: Left(RefreshFailure(null, profile)));
  }

  Result<Either<ResponseEntity, T>> refreshProfile(T profile) {
    final operation = internalRefreshProfile(profile);
    if (operation != null) {
      operation.converter ??= refreshConverter;
      operation.dataConverter ??= (r) => r.updateToken(profile.userToken);
      final result = handleResponseOperation(operation);
      return result.next(
        (value) => value.leftMap((l) => handleReAuthFailure(l, profile)),
      );
    }
    return const Result(value: Left(Failure()));
  }

  ResponseEntity handleReAuthFailure(
    ResponseEntity responseEntity, [
    T? oldAccount,
  ]) {
    if (oldAccount != null) {
      return RefreshFailure(
        responseEntity.message,
        oldAccount,
        baseFailure: responseEntity is Failure ? responseEntity : null,
      );
    } else {
      return responseEntity;
    }
  }

  Result<ResponseEntity> saveProfileIfRemembered(T profile) {
    return requireUser((user) {
      if (profile.active) {
        saveAccount(profile);
      }
      return const Success().asResult;
    });
  }

  Result<ResponseEntity> offlineSignOut() {
    final result = saveAccount(null).then<ResponseEntity>((value) {
      return const Success();
    }).catchError((e, s) {
      print(e);
      print(s);
      return UnknownFailure(e, getErrorMessage(e));
    });
    return result.asResult;
  }

  Result<ResponseEntity> signOut(T account) {
    final operation = internalLogout(account);
    if (operation != null) {
      return handleApiResponse(
        operation,
        interceptData: (_) {
          saveAccount(null);
        },
      );
    }
    return offlineSignOut();
  }
}
