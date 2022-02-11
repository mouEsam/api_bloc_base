import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/work.dart';

import '_defs.dart';
import 'lifecycle_observer.dart';
import 'provider_mixin.dart';
import 'state.dart';

export 'state.dart';

abstract class ProviderBloc<Input, Output> extends StatefulProviderBloc<Output>
    with
        ProviderMixin<Output>,
        TrafficLightsProviderMixin<Output>,
        LifecycleProviderMixin<Output>,
        ListenableProviderMixin<Output>,
        ListenerStateProviderMixin<Output>,
        SourcesProviderMixin<Input, Output>,
        OutputInjectorProviderMixin<Input, Output> {
  final LifecycleObserver? appLifecycleObserver;
  final List<ProviderMixin> providers;
  final List<Stream<ProviderState>> sources;

  final bool canRunWithoutListeners;

  ProviderBloc({
    this.appLifecycleObserver,
    this.sources = const [],
    this.providers = const [],
    this.canRunWithoutListeners = true,
  }) : super(ProviderLoading());

  @override
  void handleOutput(Work output) {
    emitState(output.state);
  }
}
