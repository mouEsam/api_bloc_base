import 'dart:async';

import 'package:api_bloc_base/src/data/model/_index.dart';
import 'package:api_bloc_base/src/domain/entity/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/_index.dart';
import 'package:dartz/dartz.dart';

abstract class ProviderConverter<Input, Output>
    extends ProviderBloc<Input, Output>
    with ProviderListenerProviderMixin<Input, Output> {

  final ProviderMixin<Input> provider;

  ProviderConverter(
    this.provider, {
    Input? initialInput,
    Result<Either<ResponseEntity, Input>>? singleDataSource,
    Either<ResponseEntity, Stream<Input>>? streamDataSource,
    LifecycleObserver? appLifecycleObserver,
    List<ProviderMixin> providers = const [],
    List<Stream<ProviderState>> sources = const [],
    bool enableRefresh = true,
    bool enableRetry = true,
    bool canRunWithoutListeners = true,
    bool refreshOnAppActive = true,
    bool fetchOnCreate = true,
  }) : super(
          initialInput: initialInput,
          singleDataSource: singleDataSource,
          streamDataSource: streamDataSource,
          appLifecycleObserver: appLifecycleObserver,
          sources: sources,
          providers: providers,
          enableRefresh: enableRefresh,
          enableRetry: enableRetry,
          refreshOnAppActive: refreshOnAppActive,
          canRunWithoutListeners: canRunWithoutListeners,
          fetchOnCreate: fetchOnCreate,
        );
}
