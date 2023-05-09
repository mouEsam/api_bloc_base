import 'package:api_bloc_base/src/data/_index.dart';
import 'package:api_bloc_base/src/domain/entity/_index.dart';
import 'package:dartz/dartz.dart';

mixin UserProfileUtilsMixin<T extends BaseProfile<T>> on BaseRepository {
  UserDefaults get userDefaults;

  String get noAccountSavedInError;

  Future<bool> get _wasSaved async {
    return (await userDefaults.signedAccount) != null;
  }

  Future<void> overwriteSavedAccount(T account) async {
    if (await _wasSaved) {
      return saveAccount(account);
    }
  }

  Future<void> overwriteSavedAccountIfActive(T account) async {
    if (account.active == true) {
      return overwriteSavedAccount(account);
    }
  }

  Future<void> saveAccount(T? account) {
    final one = userDefaults.setSignedAccount(account);
    final two = userDefaults.setUserToken(account?.accessToken);
    return Future.wait([one, two]);
  }

  Result<ResponseEntity> requireUser(
      Result<ResponseEntity> Function(T user) action) {
    return userDefaults.signedAccount.maybe.next((savedAccount) {
      if (savedAccount is T) {
        return action(savedAccount);
      }
      return Result(value: NoAccountSavedFailure(noAccountSavedInError));
    });
  }

  Result<D> withUser<D>(Result<D> Function(T? user) action) {
    return userDefaults.signedAccount.maybe.next((savedAccount) {
      return action(savedAccount as T?);
    });
  }

  Result<Either<ResponseEntity, D>> dataRequireUser<D>(
      Result<Either<ResponseEntity, D>> Function(T user) action) {
    return userDefaults.signedAccount.maybe.next((savedAccount) {
      if (savedAccount is T) {
        return action(savedAccount);
      }
      return Result(value: Left(NoAccountSavedFailure(noAccountSavedInError)));
    });
  }

  Result<Either<ResponseEntity, D>> dataWithUser<D>(
      Result<Either<ResponseEntity, D>> Function(T? user) action) {
    return withUser(action);
  }
}
