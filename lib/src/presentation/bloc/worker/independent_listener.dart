import 'dart:async';

import 'package:api_bloc_base/src/data/_index.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/worker/listener_bloc.dart';
import 'package:dartz/dartz.dart';

import '_defs.dart';

abstract class IndependentListener<Input, Output>
    extends ListenerBloc<Input, Output>
    with
        LifecycleWorkerMixin<Output>,
        ListenableWorkerMixin<Output>,
        InputSinkWorkerMixin<Input, Output>,
        StreamInputWorkerMixin<Input, Output>,
        IndependenceWorkerMixin<Input, Output> {
  final Result<Either<ResponseEntity, Input>>? singleDataSource;
  final Either<ResponseEntity, Stream<Input>>? dataStreamSource;
  final Stream<Either<ResponseEntity, Input>>? streamDataSource;

  final LifecycleObserver? appLifecycleObserver;

  final bool enableRefresh;
  final bool enableRetry;
  final bool canRunWithoutListeners;
  final bool refreshOnActive;
  final bool refreshOnAppActive;

  IndependentListener(
      {List<Stream<BlocState>> sources = const [],
      List<ProviderMixin> providers = const [],
      this.singleDataSource,
      this.dataStreamSource,
      this.streamDataSource,
      this.appLifecycleObserver,
      this.enableRefresh = true,
      this.enableRetry = true,
      this.canRunWithoutListeners = true,
      this.refreshOnAppActive = true,
      this.refreshOnActive = false,
      bool fetchOnCreate = true,
      Output? currentData})
      : super(sources, providers, currentData: currentData) {
    if (fetchOnCreate) {
      beginFetching();
    }
  }
}
