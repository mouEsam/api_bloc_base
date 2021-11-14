import 'dart:async';

import 'package:api_bloc_base/src/data/repository/base_repository.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/independence_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/lifecycle_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/listenable_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/lifecycle_observer.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/provider.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/state.dart';
import 'package:api_bloc_base/src/presentation/bloc/worker/listener_bloc.dart';
import 'package:dartz/dartz.dart';

abstract class IndependentListener<Input, Output>
    extends ListenerBloc<Input, Output>
    with
        LifecycleMixin<WorkerState<Output>>,
        ListenableMixin<WorkerState<Output>>,
        IndependenceMixin<Input, Output, WorkerState<Output>> {
  final Result<Either<ResponseEntity, Input>>? singleDataSource;
  final Either<ResponseEntity, Stream<Input>>? streamDataSource;

  final LifecycleObserver? appLifecycleObserver;

  final bool enableRefresh;
  final bool enableRetry;
  final bool canRunWithoutListeners;

  IndependentListener(
      {List<Stream<ProviderState>> sources = const [],
      List<ProviderBloc> providers = const [],
      this.singleDataSource,
      this.streamDataSource,
      this.appLifecycleObserver,
      this.enableRefresh = true,
      this.enableRetry = true,
      this.canRunWithoutListeners = true,
      bool getOnCreate = true,
      Output? currentData})
      : super(sources, providers, currentData: currentData) {
    if (getOnCreate) {
      fetchData();
    }
  }
}
