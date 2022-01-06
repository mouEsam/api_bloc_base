import 'dart:async';

import 'package:api_bloc_base/src/data/repository/base_repository.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/listenable_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/refreshable.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/stateful_bloc.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/traffic_lights_mixin.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';

import 'state.dart';

export 'state.dart';

mixin IndependenceMixin<Input, Output, State extends BlocState>
    on
        StatefulBloc<Output, State>,
        TrafficLightsMixin<State>,
        ListenableMixin<State>
    implements Refreshable {
  final ValueNotifier<bool> _canFetchData = ValueNotifier(false);
  final ValueNotifier<bool> _alreadyFetchedData = ValueNotifier(false);
  final ValueNotifier<bool> _needsToRefresh = ValueNotifier(false);
  final ValueNotifier<bool> _needsToRefetch = ValueNotifier(false);
  final Duration? refreshInterval = Duration(seconds: 30);
  final Duration? retryInterval = Duration(seconds: 30);

  Result<Either<ResponseEntity, Input>>? get singleDataSource;
  Either<ResponseEntity, Stream<Input>>? get streamDataSource;

  bool get enableRefresh;
  bool get enableRetry;

  StreamSubscription<Input>? _streamSourceSubscription;

  @override
  get subscriptions => super.subscriptions..addAll([_streamSourceSubscription]);
  @override
  get trafficLights => super.trafficLights..addAll([_canFetchData]);
  @override
  get notifiers => super.notifiers
    ..addAll(
        [_needsToRefresh, _needsToRefetch, _canFetchData, _alreadyFetchedData]);
  @override
  get timers => super.timers..addAll([_timer]);

  Timer? _timer;

  @mustCallSuper
  void handleState(State state) {
    setupTimer();
  }

  void beginFetching() {
    _canFetchData.value = true;
  }

  @mustCallSuper
  Future<void> fetchData({bool refresh = false}) async {
    if (!_canFetchData.value) {
      _canFetchData.value = true;
    }
    if (!_alreadyFetchedData.value) {
      _alreadyFetchedData.value = true;
    }
    if (!refresh) {
      emitLoading();
    }
    if (lastTrafficLightsValue) {
      final singleSource = this.singleDataSource;
      final streamSource = this.streamDataSource;
      if (singleSource != null) {
        await _handleSingleSource(singleSource, refresh);
      } else if (streamSource != null) {
        _handleStreamSource(streamSource);
      }
    }
  }

  void clean() {
    _alreadyFetchedData.value = false;
    super.clean();
  }

  Future<void> refetchData() {
    clean();
    return fetchData(refresh: false);
  }

  Future<void> refreshData() {
    return fetchData(refresh: true);
  }

  Future<void> _handleSingleSource(
      Result<Either<ResponseEntity, Input>> singleSource, bool refresh) async {
    final future = await singleSource.resultFuture;
    return future.fold(
      (l) async {
        injectInputState(Error(l));
      },
      (r) {
        return _handleStreamSource(Right(Stream.value(r)));
      },
    );
  }

  void _handleStreamSource(Either<ResponseEntity, Stream<Input>> streamSource) {
    return streamSource.fold(
      (l) async {
        injectInputState(Error(l));
      },
      (r) {
        _streamSourceSubscription?.cancel();
        _streamSourceSubscription = r.listen(injectInput);
      },
    );
  }

  void setupTimer() {
    if (state is Error && enableRetry) {
      if (retryInterval != null) {
        _timer?.cancel();
        _timer = Timer(retryInterval!, fetchData);
      }
    } else if (state is Loaded<Output> &&
        enableRefresh &&
        hasData &&
        _canFetchData.value) {
      if (refreshInterval != null) {
        _timer?.cancel();
        _timer = Timer.periodic(refreshInterval!, (_) => refreshData());
      }
    }
  }

  void injectInput(Input input);
  void injectInputState(BlocState input);

  void markNeedsRefetch() {
    _needsToRefetch.value = true;
    if (lastTrafficLightsValue) {
      _performMarkedRefetch();
    }
  }

  void _performMarkedRefetch() {
    _needsToRefetch.value = false;
    refetchData();
  }

  void markNeedsRefresh() {
    _needsToRefresh.value = true;
    if (lastTrafficLightsValue) {
      _performMarkedRefresh();
    }
  }

  void _performMarkedRefresh() {
    _needsToRefresh.value = false;
    refreshData();
  }

  @mustCallSuper
  void trafficLightsChanged(bool green) {
    if (green) {
      _streamSourceSubscription?.resume();
      if (!_alreadyFetchedData.value) {
        fetchData();
      } else if (_needsToRefetch.value) {
        _performMarkedRefetch();
      } else if (_needsToRefresh.value) {
        _performMarkedRefresh();
      }
      setupTimer();
    } else {
      _streamSourceSubscription?.pause();
      _timer?.cancel();
    }
  }
}
