import 'dart:async';

import 'package:api_bloc_base/src/data/_index.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/independence_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/lifecycle_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/listenable_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/worker/listener_bloc.dart';
import 'package:dartz/dartz.dart';

import '_defs.dart';

abstract class IndependentListener<Input, Output>
    extends ListenerBloc<Input, Output>
    with
        LifecycleWorkerMixin<Output>,
        ListenableWorkerMixin<Output>,
        IndependenceWorkerMixin<Input, Output> {
  final Result<Either<ResponseEntity, Input>>? singleDataSource;
  final Either<ResponseEntity, Stream<Input>>? streamDataSource;

  final LifecycleObserver? appLifecycleObserver;

  final bool enableRefresh;
  final bool enableRetry;
  final bool canRunWithoutListeners;
  final bool refreshOnAppActive;

  IndependentListener(
      {List<Stream<ProviderState>> sources = const [],
      List<ProviderMixin> providers = const [],
      this.singleDataSource,
      this.streamDataSource,
      this.appLifecycleObserver,
      this.enableRefresh = true,
      this.enableRetry = true,
      this.canRunWithoutListeners = true,
      this.refreshOnAppActive = true,
      bool fetchOnCreate = true,
      Output? currentData})
      : super(sources, providers, currentData: currentData) {
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
