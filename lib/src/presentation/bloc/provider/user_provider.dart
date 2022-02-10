import 'dart:async';

import 'package:api_bloc_base/src/domain/entity/base_profile.dart';
import 'package:api_bloc_base/src/presentation/bloc/user/base_user_bloc.dart';
import 'package:api_bloc_base/src/presentation/bloc/worker/_index.dart';
import 'package:dartz/dartz.dart';
import 'package:rxdart/rxdart.dart';

import '_defs.dart';
import 'lifecycle_observer.dart';
import 'provider.dart';

class SimpleUserProvider<UserType extends BaseProfile<UserType>>
    extends ProviderBloc<UserType, UserType>
    with SameInputOutputProviderMixin<UserType> {
  final BaseUserBloc<UserType> userBloc;

  SimpleUserProvider(this.userBloc, LifecycleObserver appLifecycleObserver)
      : super(
          refreshOnAppActive: false,
          fetchOnCreate: true,
          enableRetry: false,
          enableRefresh: false,
          canRunWithoutListeners: true,
          streamDataSource: Right(userBloc.userStream.whereType<UserType>()),
          appLifecycleObserver: appLifecycleObserver,
        );

  @override
  FutureOr<void> refreshData() {
    return userBloc.autoSignIn(true);
  }
}
