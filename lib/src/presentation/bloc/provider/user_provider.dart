import 'package:api_bloc_base/src/domain/entity/base_profile.dart';
import 'package:api_bloc_base/src/presentation/bloc/user/base_user_bloc.dart';
import 'package:api_bloc_base/src/presentation/bloc/worker/_index.dart';
import 'package:dartz/dartz.dart';
import 'package:rxdart/rxdart.dart';

import 'lifecycle_observer.dart';
import 'provider.dart';

class SimpleUserProvider<UserType extends BaseProfile>
    extends ProviderBloc<UserType, UserType>
    with SameInputOutputMixin<UserType, ProviderState<UserType>> {
  final BaseUserBloc<UserType> userBloc;

  SimpleUserProvider(this.userBloc, LifecycleObserver appLifecycleObserver)
      : super(
          fetchOnCreate: true,
          streamDataSource: Right(userBloc.userStream.whereType<UserType>()),
          appLifecycleObserver: appLifecycleObserver,
        );

  @override
  Future<void> refreshData() {
    return userBloc.autoSignIn(true);
  }
}
