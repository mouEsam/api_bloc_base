import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/state.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/work.dart';
import 'package:async/async.dart' as async;
import 'package:dartz/dartz.dart';
import 'package:rxdart/rxdart.dart';

import 'lifecycle_observer.dart';
import 'provider_mixin.dart';
import 'state.dart';
import '_defs.dart';

export 'state.dart';

class ProviderWrapper<Output> extends StatefulProviderBloc<Output>
    with ProviderMixin<Output> {
  var _dataFuture = Completer<Output?>();
  var _stateFuture = Completer<ProviderState<Output>>();
  Future<Output?> get dataFuture => _dataFuture.future;
  Future<ProviderState<Output>> get stateFuture => _stateFuture.future;
  bool get hasData => _latestData != null;
  Output? _latestData;

  Output? get latestData => _latestData;

  StreamSubscription? _subscription;

  get subscriptions => super.subscriptions..add(_subscription);

  final FutureOr<void> Function({bool refresh})? onFetchData;
  final FutureOr<void> Function()? onRefreshData;
  final FutureOr<void> Function()? onRefetchData;

  ProviderWrapper(
    Stream<ProviderState<Output>> stream, {
    this.onFetchData,
    this.onRefreshData,
    this.onRefetchData,
  }) : super(ProviderLoading()) {
    _subscription = stream.listen((event) {
      emitState(event);
    });
  }

  @override
  void stateChanged(ProviderState<Output> nextState) {
    if (nextState is ProviderLoaded<Output>) {
      _latestData = nextState.data;
      if (_dataFuture.isCompleted) {
        _dataFuture = Completer();
      }
      _dataFuture.complete(nextState.data);
    }
    if (_stateFuture.isCompleted) {
      _stateFuture = Completer();
    }
    _stateFuture.complete(nextState);
    super.stateChanged(nextState);
  }

  void clean() {
    _latestData = null;
    _dataFuture = Completer();
    super.clean();
  }

  @override
  FutureOr<void> fetchData({bool refresh = false}) =>
      onFetchData?.call(refresh: refresh);

  @override
  FutureOr<void> refetchData() => onRefetchData?.call();

  @override
  FutureOr<void> refreshData() => onRefreshData?.call();
}
