import 'dart:async';

import 'package:api_bloc_base/src/domain/entity/base_profile.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/user/base_user_bloc.dart';
import 'package:flutter/cupertino.dart';

import 'provider.dart';
import 'state.dart';
import 'user_dependant_state.dart';

mixin UserDependantProviderMixin<Data, Profile extends BaseProfile>
    on ProviderBloc<Data> {
  DateTime? _lastLogin;
  BaseUserBloc<Profile> get userBloc;
  String? authToken;
  get userId => userBloc.currentUser?.id;
  String get requireAuthToken => authToken!;
  StreamSubscription? _subscription;

  final ValueNotifier<bool> userIsGreen = ValueNotifier(false);

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
              _lastLogin = DateTime.now();
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

  ProviderState<Data> createLoadedState(Data data) {
    return UserDependentProviderLoadedState<Data>(data, _lastLogin);
  }

  ProviderState<Data> createErrorState(ResponseEntity response) {
    return UserDependentProviderErrorState<Data>(response, _lastLogin);
  }
}
