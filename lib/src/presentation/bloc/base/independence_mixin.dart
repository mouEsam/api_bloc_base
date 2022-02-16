import 'dart:async';

import 'package:api_bloc_base/src/data/model/_index.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/listenable_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/refreshable.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/stateful_bloc.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/traffic_lights_mixin.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';

import 'input_sink.dart';
import 'state.dart';
import 'stream_input.dart';

mixin IndependenceMixin<Input, Output, State extends BlocState>
    on
        StatefulBloc<Output, State>,
        TrafficLightsMixin<State>,
        ListenableMixin<State>,
        InputSinkMixin<Input, Output, State>,
        StreamInputMixin<Input, Output, State>
    implements Refreshable {
  final ValueNotifier<bool> _canFetchData = ValueNotifier(false);
  final ValueNotifier<bool> _alreadyFetchedData = ValueNotifier(false);
  final ValueNotifier<bool> _needsToRefresh = ValueNotifier(false);
  final ValueNotifier<bool> _needsToRefetch = ValueNotifier(false);
  final Duration? refreshInterval = Duration(seconds: 30);
  final Duration? retryInterval = Duration(seconds: 30);

  Result<Either<ResponseEntity, Input>>? get singleDataSource;
  Either<ResponseEntity, Stream<Input>>? get dataStreamSource;
  Stream<Either<ResponseEntity, Input>>? get streamDataSource;

  bool get enableRefresh;
  bool get enableRetry;
  bool get refreshOnAppActive;

  StreamSubscription<Either<ResponseEntity, Input>>? _streamSourceSubscription;
  StreamSubscription<Input>? _dataSourceSubscription;
  bool _hasSingleSource = false;

  @override
  get subscriptions => super.subscriptions
    ..addAll([_streamSourceSubscription, _dataSourceSubscription]);
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
  void stateChanged(State state) {
    if (_hasSingleSource) {
      setupTimer();
    }
    super.stateChanged(state);
  }

  void beginFetching() {
    _canFetchData.value = true;
  }

  @mustCallSuper
  FutureOr<void> fetchData({bool refresh = false}) async {
    if (!_canFetchData.value) {
      _canFetchData.value = true;
    }
    if (lastTrafficLightsValue) {
      if (!refresh) {
        emitLoading();
      }
      if (!_alreadyFetchedData.value) {
        _alreadyFetchedData.value = true;
      }
      try {
        final singleSource = this.singleDataSource;
        final dataSource = this.dataStreamSource;
        final streamSource = this.streamDataSource;
        _hasSingleSource = singleSource != null;
        if (_hasSingleSource) {
          await _handleSingleSource(singleSource!);
        } else if (dataSource != null) {
          _handleStreamSource(dataSource);
        } else if (streamSource != null) {
          _handleDataSource(streamSource);
        }
      } catch (e, s) {
        injectInputState(createErrorState(createFailure(e, s)));
      }
    }
  }

  void clean() {
    _alreadyFetchedData.value = false;
    super.clean();
  }

  FutureOr<void> refetchData() {
    print("called refetchData");
    clean();
    return fetchData(refresh: false);
  }

  FutureOr<void> refreshData() {
    return fetchData(refresh: true);
  }

  FutureOr<void> _handleSingleSource(
      Result<Either<ResponseEntity, Input>> singleSource) async {
    final future = await singleSource.value;
    return future.fold(
      (l) {
        return injectInputState(Error(l));
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
        _dataSourceSubscription?.cancel();
        _dataSourceSubscription = r.listen(injectInput);
      },
    );
  }

  void _handleDataSource(Stream<Either<ResponseEntity, Input>> streamSource) {
    _streamSourceSubscription?.cancel();
    _streamSourceSubscription = streamSource.listen((event) {
      _handleSingleSource(event.asResult);
    });
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
      if (refreshOnAppActive) {
        markNeedsRefresh();
      }
      if (_hasSingleSource) {
        setupTimer();
      }
    } else {
      _streamSourceSubscription?.pause();
      _timer?.cancel();
    }
    super.trafficLightsChanged(green);
  }
}
