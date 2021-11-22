import 'package:api_bloc_base/src/domain/entity/base_profile.dart';
import 'package:equatable/equatable.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [];
}

class UserLoadingState extends UserState {
  const UserLoadingState();

  @override
  List<Object> get props => [];
}

abstract class BaseSignedInState<T extends BaseProfile> extends UserState {
  final T userAccount;

  const BaseSignedInState(this.userAccount);

  @override
  List<Object> get props => [
        this.userAccount,
      ];
}

class SignedOutState extends UserState {
  const SignedOutState();
}

class TokenRefreshFailedState<T extends BaseProfile> extends SignedOutState {
  final T oldAccount;

  TokenRefreshFailedState(this.oldAccount) : super();

  @override
  List<Object> get props => [...super.props, this.oldAccount];
}
