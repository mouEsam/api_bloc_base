import 'dart:async';

import 'package:api_bloc_base/src/data/_index.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';

import '../base/state.dart';
import 'state.dart';

mixin ProviderMixin<Data> on StatefulBloc<Data, ProviderState<Data>>
    implements Refreshable {
  @mustCallSuper
  Future<void> fetchData({bool refresh = false});
  Future<void> refreshData();
  Future<void> refetchData();
  void clean();

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
    if (state is Loading) {
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
    result.resultFuture.then((value) {
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
    result.resultFuture.then((value) {
      if (value is Success) {
        onSuccess?.call();
      } else if (value is Failure) {
        onFailure?.call();
      }
    });
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
