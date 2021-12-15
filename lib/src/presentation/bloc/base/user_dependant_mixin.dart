import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/independence_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/user/base_user_bloc.dart';

mixin UserDependantMixin<Input, Output, State extends BlocState>
    on IndependenceMixin<Input, Output, State> {
  BaseUserBloc get userBloc;
  String? authToken;
  get userId => userBloc.currentUser?.id;
  String get requireAuthToken => authToken!;
  late StreamSubscription _userSubscription;

  get subscriptions => super.subscriptions..add(_userSubscription);

  void init() {
    setUpUserListener();
    super.init();
  }

  bool _init = false;
  void setUpUserListener() {
    if (_init) return;
    _init = true;
    _userSubscription = userBloc.userStream.listen(
      (user) {
        final newToken = user?.accessToken;
        if (newToken != null) {
          if (newToken != authToken) {
            authToken = newToken;
            refreshData();
          }
        } else {
          authToken = null;
        }
      },
    );
  }
}
