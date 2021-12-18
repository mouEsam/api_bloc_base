import 'dart:async';

import 'package:api_bloc_base/src/domain/entity/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/independence_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/user/base_user_bloc.dart';
import 'package:flutter/foundation.dart';

mixin UserDependantMixin<Input, Output, State extends BlocState,
    Profile extends BaseProfile> on IndependenceMixin<Input, Output, State> {
  DateTime? lastLogin;
  BaseUserBloc<Profile> get userBloc;
  String? authToken;
  get userId => userBloc.currentUser?.id;
  String get requireAuthToken =>
      userBloc.currentUser?.accessToken ?? authToken!;
  StreamSubscription? _subscription;

  late final ValueNotifier<bool> userIsGreen = ValueNotifier(
      userBloc.currentUser != null && shouldStart(userBloc.currentUser!));

  @override
  get trafficLights => super.trafficLights..addAll([userIsGreen]);
  @override
  get subscriptions => super.subscriptions..addAll([_subscription]);

  bool _isAGo = false;

  bool get isAGo => _isAGo;

  @override
  void init() {
    setupUserListener();
    super.init();
  }

  bool _init = false;
  void setupUserListener() {
    if (_init) return;
    _init = true;
    _subscription = userBloc.userStream.distinct().listen(
      (user) {
        final newToken = user?.accessToken;
        if (newToken != null) {
          if (newToken != authToken) {
            authToken = newToken;
            if (shouldStart(user!)) {
              lastLogin = DateTime.now();
              userIsGreen.value = true;
            }
          }
        } else {
          authToken = null;
          userIsGreen.value = false;
        }
      },
    );
  }

  bool shouldStart(Profile user) => true;
}
