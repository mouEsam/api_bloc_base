import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/listenable_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/listener_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/_index.dart';

import 'input_sink.dart';
import 'input_to_output.dart';

mixin ProviderListenerMixin<Input, Output, State extends BlocState>
    on
        ListenerMixin<State>,
        InputSinkMixin<Input, Output, State>,
        OutputConverterMixin<Input, Output, State>
    implements Refreshable {
  late final StreamSubscription _blocSubscription;

  ProviderMixin<Input> get provider;

  @override
  get subscriptions => super.subscriptions..addAll([_blocSubscription]);

  bool _init = false;
  @override
  void init() {
    if (_init) return;
    _init = true;
    _setupProviderListener();
    super.init();
  }

  void _setupProviderListener() {
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
