import 'dart:async';

import 'package:api_bloc_base/src/data/_index.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/lifecycle_observer.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/provider.dart';
import 'package:api_bloc_base/src/presentation/bloc/worker/independent_listener.dart';
import 'package:dartz/dartz.dart';

import 'pagination_mixin.dart';

abstract class PaginatedListener<Paginated extends PaginatedInput<Output>,
        Output> extends IndependentListener<Paginated, PaginatedOutput<Output>>
    with PaginationMixin<Paginated, Output> {
  PaginatedListener(
      {List<Stream<BlocState>> sources = const [],
      List<ProviderBloc> providers = const [],
      Result<Either<ResponseEntity, Paginated>>? singleDataSource,
      Either<ResponseEntity, Stream<Paginated>>? dataStreamSource,
      Stream<Either<ResponseEntity, Paginated>>? streamDataSource,
      LifecycleObserver? appLifecycleObserver,
      bool enableRefresh = false,
      bool refreshOnActive = false,
      bool refreshOnAppActive = false,
      bool enableRetry = true,
      bool fetchOnCreate = true,
      PaginatedOutput<Output>? currentData})
      : super(
            sources: sources,
            providers: providers,
            singleDataSource: singleDataSource,
            dataStreamSource: dataStreamSource,
            streamDataSource: streamDataSource,
            appLifecycleObserver: appLifecycleObserver,
            enableRefresh: enableRefresh,
            refreshOnActive: refreshOnActive,
            refreshOnAppActive: refreshOnAppActive,
            enableRetry: enableRetry,
            fetchOnCreate: fetchOnCreate,
            currentData: currentData);
}
