import 'dart:async';

import 'package:api_bloc_base/src/data/repository/base_repository.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/lifecycle_observer.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/provider.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/state.dart';
import 'package:api_bloc_base/src/presentation/bloc/worker/independent_listener.dart';
import 'package:dartz/dartz.dart';

import 'pagination_mixin.dart';

abstract class PaginatedListener<Paginated extends PaginatedInput<Output>,
        Output> extends IndependentListener<Paginated, Output>
    with PaginationMixin<Paginated, Output> {
  PaginatedListener(
      {List<Stream<ProviderState>> sources = const [],
      List<ProviderBloc> providers = const [],
      Result<Either<ResponseEntity, Paginated>>? singleDataSource,
      Either<ResponseEntity, Stream<Paginated>>? streamDataSource,
      LifecycleObserver? appLifecycleObserver,
      bool enableRefresh = true,
      bool enableRetry = true,
      bool fetchOnCreate = true,
      Output? currentData})
      : super(
            sources: sources,
            providers: providers,
            singleDataSource: singleDataSource,
            streamDataSource: streamDataSource,
            appLifecycleObserver: appLifecycleObserver,
            enableRefresh: enableRefresh,
            enableRetry: enableRetry,
            fetchOnCreate: fetchOnCreate,
            currentData: currentData);
}
