import 'dart:async';

import 'package:api_bloc_base/src/domain/entity/base_profile.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/user/base_user_bloc.dart';

import '_defs.dart';
import 'lifecycle_observer.dart';

class SimpleUserProvider<UserType extends BaseProfile<UserType>>
    extends ProviderBloc<UserType, UserType>
    with SameInputOutputProviderMixin<UserType> {
  final BaseUserBloc<UserType> userBloc;

  @override
  get inputStream => userBloc.profileStream;

  SimpleUserProvider(this.userBloc, LifecycleObserver appLifecycleObserver)
      : super(
          canRunWithoutListeners: true,
          appLifecycleObserver: appLifecycleObserver,
        );

  @override
  FutureOr<void> refreshData() {
    return userBloc.autoSignIn(true);
  }

  @override
  FutureOr<void> refetchData() {
    return userBloc.autoSignIn(false);
  }
}
