import 'dart:async';

import 'package:api_bloc_base/src/domain/entity/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/independence_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/user/base_user_bloc.dart';
import 'package:flutter/foundation.dart';

import 'state.dart';

mixin UserDependantMixin<Input, Output, State extends BlocState,
        Profile extends BaseProfile<Profile>>
    on IndependenceMixin<Input, Output, State> {
  DateTime? lastLogin;

  BaseUserBloc<Profile> get userBloc;

  Profile? get safeCurrentUser => userBloc.currentUser;

  Profile get currentUser => safeCurrentUser!;
  String? authToken;

  get userId => safeCurrentUser?.id;

  String get requireAuthToken =>
      userBloc.currentUser?.accessToken ?? authToken!;
  StreamSubscription? _subscription;

  ValueListenable<bool> get userIsGreen => _userIsGreen;

  late final ValueNotifier<bool> _userIsGreen = ValueNotifier(
    userBloc.currentUser != null && shouldStart(userBloc.currentUser!),
  );

  @override
  List<ValueListenable<bool>> get trafficLights => super.trafficLights..addAll([userIsGreen]);

  @override
  Set<StreamSubscription?> get subscriptions => super.subscriptions..addAll([_subscription]);

  bool _init = false;
  @override
  void init() {
    if (_init) return;
    _init = true;
    _setupUserListener();
    super.init();
  }

  void _setupUserListener() {
    _subscription = userBloc.userStream.distinct().listen(
      (user) {
        final newToken = user?.accessToken;
        if (newToken != null) {
          authToken = newToken;
          if (shouldStart(user!)) {
            lastLogin = DateTime.now();
            _userIsGreen.value = true;
          } else {
            _userIsGreen.value = false;
          }
        } else {
          authToken = null;
          _userIsGreen.value = false;
        }
      },
    );
  }

  bool shouldStart(Profile user) => true;
}
