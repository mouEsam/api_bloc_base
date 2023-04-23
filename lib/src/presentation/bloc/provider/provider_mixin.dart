import 'dart:async';

import 'package:api_bloc_base/src/data/_index.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:async/async.dart' as async;
import 'package:dartz/dartz.dart';
import 'package:rxdart/rxdart.dart';

import '_defs.dart';
import 'state.dart';

mixin ProviderMixin<Data> on StatefulProviderBloc<Data> implements Refreshable {
  @override
  get subjects => super.subjects..addAll([_dataSubject]);

  final BehaviorSubject<Data?> _dataSubject = BehaviorSubject<Data?>();
  var _dataFuture = Completer<Data?>();
  var _stateFuture = Completer<ProviderState<Data>>();

  Future<Data?> get dataFuture => _dataFuture.future;

  Future<ProviderState<Data>> get stateFuture => _stateFuture.future;

  bool get hasData => latestData != null;

  Data? get latestData => _dataSubject.valueOrNull;

  Stream<Data?> get dataStream =>
      async.LazyStream(() => _dataSubject.shareValue())
          .asBroadcastStream(onCancel: (c) => c.cancel());

  @override
  void clean() {
    _dataSubject.value = null;
    _dataFuture = Completer();
    super.clean();
  }

  FutureOr<void> refreshData();

  FutureOr<void> refetchData();

  @override
  void stateChanged(ProviderState<Data> state) {
    if (state is ProviderLoaded<Data>) {
      Data data = state.data;
      _dataSubject.add(data);
      if (_dataFuture.isCompleted) {
        _dataFuture = Completer<Data>();
      }
      _dataFuture.complete(data);
    } else if (state is Invalidated) {
      refetchData();
      return;
    }
    if (_stateFuture.isCompleted) {
      _stateFuture = Completer<ProviderState<Data>>();
    }
    _stateFuture.complete(state);
    super.stateChanged(state);
  }

  ProviderState<Data> createLoadingState() {
    return ProviderLoading<Data>();
  }

  ProviderState<Data> createLoadedState(Data data) {
    return ProviderLoaded<Data>(data);
  }

  ProviderState<Data> createErrorState(ResponseEntity message) {
    return ProviderError<Data>(message);
  }

  void emitState(BlocState state) {
    if (state is ProviderState<Data>) {
      emit(state);
    } else if (state is Loading) {
      emitLoading();
    } else if (state is Loaded<Data>) {
      emitLoaded(state.data);
    } else if (state is Error) {
      emitError(state.response);
    }
  }

  void emitLoading() {
    emit(createLoadingState());
  }

  void emitLoaded(Data data) {
    emit(createLoadedState(data));
  }

  void invalidate() {
    emit(Invalidated<Data>());
  }

  void emitError(ResponseEntity response) {
    emit(createErrorState(response));
  }

  void interceptOperation<S>(Result<Either<ResponseEntity, S>> result,
      {void onSuccess()?, void onFailure()?, void onDate(S data)?}) {
    Future.value(result.value).then((value) {
      value.fold((l) {
        if (l is Success) {
          onSuccess?.call();
        } else if (l is Failure) {
          onFailure?.call();
        }
      }, (r) {
        if (onDate != null) {
          onDate(r);
        } else if (onSuccess != null) {
          onSuccess();
        }
      });
    });
  }

  void interceptResponse(Result<ResponseEntity> result,
      {void onSuccess()?, void onFailure()?}) {
    Future.value(result.value).then((value) {
      if (value is Success) {
        onSuccess?.call();
      } else if (value is Failure) {
        onFailure?.call();
      }
    });
  }

  Either<ResponseEntity, Stream<Data>> get asStreamSource {
    return Right(stream.asyncMap((event) async {
      late final ProviderState<Data> nextNotLoading;
      if (event is! ProviderLoading<Data>) {
        nextNotLoading = event;
      } else {
        nextNotLoading = await stream
            .where((event) => event is! ProviderLoading<Data>)
            .first;
      }
      if (nextNotLoading is ProviderLoaded<Data>) {
        return nextNotLoading.data;
      } else if (nextNotLoading is ProviderError<Data>) {
        throw nextNotLoading.response;
      } else {
        throw nextNotLoading;
      }
    }));
  }

  Result<Either<ResponseEntity, Data>> get asSingleSource {
    return stream.first.then<Either<ResponseEntity, Data>>((event) async {
      late final ProviderState<Data> nextNotLoading;
      if (event is! ProviderLoading<Data>) {
        nextNotLoading = event;
      } else {
        nextNotLoading = await stream
            .where((event) => event is! ProviderLoading<Data>)
            .first;
      }
      if (nextNotLoading is ProviderLoaded<Data>) {
        return Right(nextNotLoading.data);
      } else if (nextNotLoading is ProviderError<Data>) {
        return Left(nextNotLoading.response);
      } else {
        return Left(Failure(defaultErrorMessage));
      }
    }).asResult;
  }

  Stream<ProviderState<Out>> transformStream<Out>(
      {Out? outData, Stream<Out>? outStream}) {
    return stream.flatMap<ProviderState<Out>>((value) {
      if (value is ProviderLoading<Data>) {
        return Stream.value(ProviderLoading<Out>());
      } else if (value is ProviderError<Data>) {
        return Stream.value(ProviderError<Out>(value.response));
      } else if (value is Invalidated<Data>) {
        return Stream.value(Invalidated<Out>());
      } else {
        if (outData != null) {
          return Stream.value(ProviderLoaded<Out>(outData));
        } else if (outStream != null) {
          return outStream.map((event) => ProviderLoaded<Out>(event));
        }
        return Stream.empty();
      }
    }).asBroadcastStream(onCancel: ((sub) => sub.cancel()));
  }
}
