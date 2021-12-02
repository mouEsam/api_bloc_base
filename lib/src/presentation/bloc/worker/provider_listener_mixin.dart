import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/provider/provider.dart';
import 'package:api_bloc_base/src/presentation/bloc/worker/listener_bloc.dart';

import '../base/state.dart';

mixin ProviderListenerMixin<Input, Output> on ListenerBloc<Input, Output> {
  late final StreamSubscription _blocSubscription;

  ProviderBloc<Input> get provider;

  @override
  get subscriptions => super.subscriptions..addAll([_blocSubscription]);

  @override
  void init() {
    setupProviderListener();
    super.init();
  }

  bool _init = false;
  void setupProviderListener() {
    if (_init) return;
    _init = true;
    provider.addListener(this);
    _blocSubscription =
        provider.stream.listen(injectInputState, onError: handleProviderError);
  }

  void handleProviderError(e, s) {
    print(e);
    print(s);
    injectInputState(Error(createFailure(e)));
  }

  @override
  Future<void> close() {
    provider.removeListener(this);
    return super.close();
  }
}
