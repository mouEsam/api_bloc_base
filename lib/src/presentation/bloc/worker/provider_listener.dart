import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/provider/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/worker/listener_bloc.dart';
import '_defs.dart';

abstract class ProviderListener<Input, Output>
    extends ListenerBloc<Input, Output>
    with ProviderListenerWorkerMixin<Input, Output> {
  final ProviderMixin<Input> provider;

  ProviderListener(
    this.provider, {
    List<Stream<ProviderState>> sources = const [],
    List<ProviderMixin> providers = const [],
    Output? currentData,
  }) : super(sources, providers, currentData: currentData);
}
