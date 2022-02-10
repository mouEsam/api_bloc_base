import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/provider/_index.dart';

abstract class ProviderConverter<Input, Output>
    extends ProviderBloc<Input, Output>
    with ProviderListenerProviderMixin<Input, Output> {
  final ProviderMixin<Input> provider;

  ProviderConverter(
    this.provider, {
    Input? initialInput,
    LifecycleObserver? appLifecycleObserver,
    List<ProviderMixin> providers = const [],
    List<Stream<ProviderState>> sources = const [],
    bool canRunWithoutListeners = true,
    bool fetchOnCreate = true,
  }) : super(
          initialInput: initialInput,
          appLifecycleObserver: appLifecycleObserver,
          sources: sources,
          providers: providers,
          canRunWithoutListeners: canRunWithoutListeners,
        ) {
    if (fetchOnCreate) {
      fetchData();
    }
  }
}
