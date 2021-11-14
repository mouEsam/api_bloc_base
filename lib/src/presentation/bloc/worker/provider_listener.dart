import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/provider/provider.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/state.dart';
import 'package:api_bloc_base/src/presentation/bloc/worker/listener_bloc.dart';

import 'provider_listener_mixin.dart';

abstract class ProviderListener<Input, Output>
    extends ListenerBloc<Input, Output>
    with ProviderListenerMixin<Input, Output> {
  final ProviderBloc<Input> provider;

  ProviderListener(List<Stream<ProviderState>> sources, this.provider,
      {Output? currentData})
      : super(sources, [], currentData: currentData);
}
