import 'dart:async';

import 'package:api_bloc_base/src/data/_index.dart';
import 'package:api_bloc_base/src/domain/entity/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/base_bloc.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/state.dart'
    as provider;
import 'package:dartz/dartz.dart';
import 'package:rxdart/rxdart.dart';

import 'base_user_state.dart';

abstract class BaseUserBloc<T extends BaseProfile<T>>
    extends BaseCubit<UserState> {
  final Duration? refreshInterval;
  final BaseAuthRepository<T> authRepository;
  final BehaviorSubject<T?> _userAccount = BehaviorSubject<T?>();

  Stream<T?> get userStream => _userAccount.shareValue();

  StreamSink<T?> get userSink => _userAccount.sink;

  T? get currentUser => _userAccount.valueOrNull;

  Timer? _tokenRefreshTimer;

  Stream<provider.ProviderState<T>> get profileStream =>
      userStream.map<provider.ProviderState<T>>((event) {
        if (event != null) {
          return provider.ProviderLoaded(event);
        } else {
          return provider.ProviderLoading();
        }
      });

  @override
  Set<Timer?> get timers => {_tokenRefreshTimer};

  @override
  Set<Subject> get subjects => {_userAccount};

  BaseUserBloc(this.refreshInterval, this.authRepository)
      : super(const UserLoadingState()) {
    autoSignIn();
  }

  Future<Either<ResponseEntity, T>> autoSignIn([bool silent = true]) async {
    if (!silent) {
      emit(const UserLoadingState());
    }
    final result = await authRepository.autoLogin().value;
    result.fold((l) {
      if (l is RefreshFailure<T>) {
        handleFailedRefresh(l.oldProfile, silent);
      } else {
        handleUser(null);
      }
    }, (user) => handleUser(user));
    return result;
  }

  Future<Either<ResponseEntity, T>> refreshToken() async {
    final result = await authRepository.refreshToken(currentUser!).value;
    result.fold((l) {
      handleReAuthFailure(l);
    }, (user) => handleUser(user));
    return result;
  }

  Future<Either<ResponseEntity, T>> refreshProfile() async {
    final result = await authRepository.refreshProfile(currentUser!).value;
    result.fold((l) {
      handleReAuthFailure(l);
    }, (user) => handleUser(user));
    return result;
  }

  void handleReAuthFailure(ResponseEntity response) {
    if (response is RefreshFailure<T>) {
      handleFailedRefresh(response.oldProfile, true);
    } else {
      handleUser(null);
    }
  }

  Result<Either<ResponseEntity, T>> login(Credentials credentials);

  Result<ResponseEntity> changePassword(String oldPassword, String password);

  Result<ResponseEntity> signOut() {
    final op = authRepository.signOut(currentUser!);
    Future.value(op.value).then((result) {
      if (result is Success ||
          (result is Failure && result is! InternetFailure)) {
        handleUser(null);
        return const Success();
      } else {
        return result;
      }
    });
    return op;
  }

  Result<ResponseEntity> offlineSignOut() {
    final op = authRepository.offlineSignOut();
    Future.value(op.value).then((result) {
      if (result is Success ||
          (result is Failure && result is! InternetFailure)) {
        handleUser(null);
        return const Success();
      } else {
        return result;
      }
    });
    return op;
  }

  @override
  void stateChanged(UserState nextState) {
    T? user;
    if (nextState is SignedOutState) {
      _tokenRefreshTimer?.cancel();
    } else if (nextState is BaseSignedInState<T>) {
      user = nextState.userAccount;
      handleRefresh(user);
    }
    _userAccount.add(user);
  }

  void handleRefresh(T user) {
    final token = user.userToken;
    final now = DateTime.now();
    final expiration = token.expiration;
    if (expiration == null) {
      if (refreshInterval != null) scheduleRefresh(refreshInterval!, false);
    } else if (expiration.isAfter(now)) {
      late final Duration refreshDuration;
      late final bool refreshToken;
      final interval = this.refreshInterval ?? Duration.zero;
      final diff = expiration.difference(now);
      if (interval > diff) {
        refreshDuration = diff;
        refreshToken = true;
      } else {
        refreshDuration = interval;
        refreshToken = false;
      }
      scheduleRefresh(refreshDuration, refreshToken);
    } else {
      refreshToken();
    }
  }

  void scheduleRefresh(Duration refreshDuration, bool isRefreshToken) {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = Timer(
      refreshDuration,
      () {
        if (isRefreshToken) {
          refreshToken();
        } else {
          refreshProfile();
        }
      },
    );
  }

  void handleFailedRefresh(T oldAccount, bool silent) {
    final expiration = oldAccount.userToken.expiration;
    final isValid = expiration == null || expiration.isAfter(DateTime.now());
    if (isValid) {
      handleUser(oldAccount);
    } else {
      if (silent) {
        scheduleRefresh(const Duration(seconds: 5), true);
      } else {
        emit(TokenRefreshFailedState(oldAccount));
      }
    }
  }

  Future<void> handleUser(T? user) async {
    if (user == null) {
      emit(const SignedOutState());
    } else {
      emitSignedUser(user);
    }
  }

  void emitSignedUser(T user);
}
