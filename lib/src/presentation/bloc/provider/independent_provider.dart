import 'dart:async';

import 'package:api_bloc_base/src/data/_index.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:dartz/dartz.dart';

export 'state.dart';
import '_index.dart';

abstract class IndependentProvider<Input, Output>
    extends ProviderBloc<Input, Output>
    with IndependenceProviderMixin<Input, Output> {
  final Duration? refreshInterval = Duration(seconds: 30);
  final Duration? retryInterval = Duration(seconds: 30);

  final Result<Either<ResponseEntity, Input>>? singleDataSource;
  final Either<ResponseEntity, Stream<Input>>? streamDataSource;

  final bool enableRefresh;
  final bool enableRetry;
  final bool canRunWithoutListeners;

  final bool refreshOnAppActive;

  IndependentProvider({
    Input? initialInput,
    this.singleDataSource,
    this.streamDataSource,
    LifecycleObserver? appLifecycleObserver,
    List<ProviderMixin> providers = const [],
    List<Stream<ProviderState>> sources = const [],
    this.enableRefresh = false,
    this.enableRetry = false,
    this.canRunWithoutListeners = true,
    this.refreshOnAppActive = true,
    bool fetchOnCreate = true,
  }) : super(
          initialInput: initialInput,
          appLifecycleObserver: appLifecycleObserver,
          sources: sources,
          providers: providers,
          canRunWithoutListeners: canRunWithoutListeners,
        ) {
    if (fetchOnCreate) {
      beginFetching();
    }
  }

  @override
  void onAppState(bool isActive) {
    if (isActive && refreshOnAppActive) {
      markNeedsRefresh();
    }
    super.onAppState(isActive);
  }
}
