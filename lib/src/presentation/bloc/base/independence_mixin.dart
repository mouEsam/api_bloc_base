import 'dart:async';

import 'package:api_bloc_base/src/data/repository/base_repository.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/listenable_mixin.dart';
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
        ListenableMixin<State> {
  final Duration? refreshInterval = Duration(seconds: 30);
  final Duration? retryInterval = Duration(seconds: 30);

  Result<Either<ResponseEntity, Input>>? get singleDataSource;
  Either<ResponseEntity, Stream<Input>>? get streamDataSource;

  bool get enableRefresh;
  bool get enableRetry;
  bool get forceRefresh => false;

  StreamSubscription<Input>? _streamSourceSubscription;

  @override
  get subscriptions => super.subscriptions..addAll([_streamSourceSubscription]);
  @override
  get timers => [_timer];

  Timer? _timer;

  @mustCallSuper
  void handleState(State state) {
    setupTimer();
  }

  @mustCallSuper
  Future<void> fetchData({bool refresh = false}) async {
    if (!refresh) {
      emitLoading();
    }
    final singleSource = this.singleDataSource;
    final streamSource = this.streamDataSource;
    if (lastTrafficLightsValue) {
      if (singleSource != null) {
        await _handleSingleSource(singleSource, refresh);
      } else if (streamSource != null) {
        _handleStreamSource(streamSource);
      }
    }
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
    } else if (state is Loaded<Output> && enableRefresh && hasData) {
      if (refreshInterval != null &&
          (forceRefresh || _streamSourceSubscription == null)) {
        _timer?.cancel();
        _timer = Timer.periodic(refreshInterval!, (_) => refreshData());
      }
    }
  }

  void injectInput(Input input);
  void injectInputState(BlocState input);

  @mustCallSuper
  void trafficLightsChanged(bool green) {
    if (green) {
      _streamSourceSubscription?.resume();
      setupTimer();
    } else {
      _streamSourceSubscription?.pause();
      _timer?.cancel();
    }
  }
}
