import 'dart:async';

import 'package:api_bloc_base/src/data/_index.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:dartz/dartz.dart';

import '_index.dart';

export 'state.dart';

abstract class IndependentProvider<Input, Output>
    extends ProviderBloc<Input, Output>
    with
        InputSinkProviderMixin<Input, Output>,
        StreamInputProviderMixin<Input, Output>,
        IndependenceProviderMixin<Input, Output> {
  final Duration? refreshInterval = Duration(seconds: 30);
  final Duration? retryInterval = Duration(seconds: 30);

  final Result<Either<ResponseEntity, Input>>? singleDataSource;
  final Either<ResponseEntity, Stream<Input>>? dataStreamSource;
  final Stream<Either<ResponseEntity, Input>>? streamDataSource;

  final bool enableRefresh;
  final bool enableRetry;
  final bool canRunWithoutListeners;

  final bool refreshOnActive;

  IndependentProvider({
    Input? initialInput,
    this.singleDataSource,
    this.dataStreamSource,
    this.streamDataSource,
    LifecycleObserver? appLifecycleObserver,
    List<ProviderMixin> providers = const [],
    List<Stream<ProviderState>> sources = const [],
    this.enableRefresh = false,
    this.enableRetry = false,
    this.canRunWithoutListeners = true,
    this.refreshOnActive = true,
    bool fetchOnCreate = true,
  }) : super(
          appLifecycleObserver: appLifecycleObserver,
          sources: sources,
          providers: providers,
          canRunWithoutListeners: canRunWithoutListeners,
        ) {
    if (fetchOnCreate) {
      beginFetching();
    }
    setupInitialData(initialInput);
  }

  void setupInitialData(Input? initialDate) {
    if (initialDate is Input) {
      injectInput(initialDate);
    }
  }
}
