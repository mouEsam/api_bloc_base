import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/listenable_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/worker/listener_bloc.dart';

import '../base/state.dart';

mixin ProviderListenerMixin<Input, Output> on ListenerBloc<Input, Output>
    implements Refreshable {
  late final StreamSubscription _blocSubscription;

  ProviderMixin<Input> get provider;

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
    if (provider is ListenableMixin) {
      (provider as ListenableMixin).addListener(this);
    }
    _blocSubscription =
        provider.stream.listen(injectInputState, onError: handleProviderError);
  }

  void handleProviderError(e, s) {
    print(e);
    print(s);
    injectInputState(Error(createFailure(e, s)));
  }

  FutureOr<void> refreshData() {
    return provider.refreshData();
  }

  FutureOr<void> refetchData() {
    return provider.refetchData();
  }

  @override
  Future<void> close() {
    if (provider is ListenableMixin) {
      (provider as ListenableMixin).removeListener(this);
    }
    return super.close();
  }
}
