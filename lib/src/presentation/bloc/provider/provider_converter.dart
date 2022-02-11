import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/_index.dart';

abstract class ProviderConverter<Input, Output>
    extends ProviderBloc<Input, Output>
    with
        InputSinkProviderMixin<Input, Output>,
        StreamInputProviderMixin<Input, Output>,
        ProviderListenerProviderMixin<Input, Output> {
  final ProviderMixin<Input> provider;

  ProviderConverter(
    this.provider, {
    LifecycleObserver? appLifecycleObserver,
    List<ProviderMixin> providers = const [],
    List<Stream<BlocState>> sources = const [],
    bool canRunWithoutListeners = true,
  }) : super(
          appLifecycleObserver: appLifecycleObserver,
          sources: sources,
          providers: providers,
          canRunWithoutListeners: canRunWithoutListeners,
        );
}
