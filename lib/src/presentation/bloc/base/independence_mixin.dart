import 'dart:async';

import 'package:api_bloc_base/src/data/model/_index.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/lifecycle_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/listenable_mixin.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/refreshable.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/stateful_bloc.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/traffic_lights_mixin.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'input_sink.dart';
import 'state.dart';
import 'stream_input.dart';

mixin IndependenceMixin<Input, Output, State extends BlocState>
    on
        StatefulBloc<Output, State>,
        TrafficLightsMixin<State>,
        LifecycleMixin<State>,
        ListenableMixin<State>,
        InputSinkMixin<Input, Output, State>,
        StreamInputMixin<Input, Output, State>
    implements Refreshable {
  final ValueNotifier<bool> _dataGreenLight = ValueNotifier(false);
  final ValueNotifier<bool> _canFetchData = ValueNotifier(false);
  final ValueNotifier<bool> _alreadyFetchedData = ValueNotifier(false);
  final ValueNotifier<bool?> shouldRefetchOrRefresh = ValueNotifier(null);
  final Duration? refreshInterval = const Duration(seconds: 30);
  final Duration? retryInterval = const Duration(seconds: 30);

  Result<Either<ResponseEntity, Input>>? get singleDataSource;

  Either<ResponseEntity, Stream<Input>>? get dataStreamSource;

  Stream<Either<ResponseEntity, Input>>? get streamDataSource;

  bool get enableRefresh;

  bool get refreshIsRefetch;

  bool get enableRetry;

  bool get refreshOnActive;

  bool get refreshOnAppActive;

  StreamSubscription<Either<ResponseEntity, Input>>? _streamSourceSubscription;
  StreamSubscription<Input>? _dataSourceSubscription;
  bool _hasSingleSource = false;

  @override
  Set<StreamSubscription?> get subscriptions => super.subscriptions
    ..addAll([_streamSourceSubscription, _dataSourceSubscription]);

  @override
  List<ValueListenable<bool>> get trafficLights => super.trafficLights
    ..addAll([
      _dataGreenLight,
    ]);

  @override
  Set<Listenable> get notifiers => super.notifiers
    ..addAll([
      shouldRefetchOrRefresh,
      _canFetchData,
      _alreadyFetchedData,
    ]);

  @override
  Set<Timer?> get timers => super.timers..addAll([_timer]);

  Timer? _timer;

  @override
  void init() {
    super.init();
    Listenable.merge([_canFetchData, _alreadyFetchedData]).addListener(() {
      _dataGreenLight.value = _canFetchData.value | _alreadyFetchedData.value;
    });
  }

  @override
  @mustCallSuper
  void stateChanged(State state) {
    if (_hasSingleSource) {
      setupTimer();
    }
    super.stateChanged(state);
  }

  void setHasData() {
    _alreadyFetchedData.value = true;
  }

  void beginFetching() {
    _canFetchData.value = true;
  }

  @mustCallSuper
  FutureOr<void> fetchData({
    bool refresh = false,
    bool remember = false,
    VoidCallback? preCall,
  }) async {
    if (!_canFetchData.value) {
      _canFetchData.value = true;
    }
    if (lastTrafficLightsValue) {
      _timer?.cancel();
      preCall?.call();
      if (!_alreadyFetchedData.value) {
        _alreadyFetchedData.value = true;
      }
      try {
        _hasSingleSource = await fetchSingleData();
        if (!refresh) {
          fetchStream();
          fetchStreamData();
        }
      } catch (e, s) {
        injectInputState(createErrorState(createFailure(e, s)));
      }
    } else if (remember) {
      if (refresh) {
        markNeedsRefresh();
      } else {
        markNeedsRefetch();
      }
    }
  }

  @mustCallSuper
  FutureOr<bool> fetchSingleData() async {
    final singleSource = singleDataSource;
    if (singleSource != null) {
      await _handleSingleSource(singleSource);
    }
    return singleSource != null;
  }

  @mustCallSuper
  bool fetchStream() {
    final dataSource = dataStreamSource;
    if (dataSource != null) {
      _handleStreamSource(dataSource);
    }
    return dataSource != null;
  }

  @mustCallSuper
  bool fetchStreamData() {
    final streamSource = streamDataSource;
    if (streamSource != null) {
      _handleDataSource(streamSource);
    }
    return streamSource != null;
  }

  @override
  void clean() {
    _alreadyFetchedData.value = false;
    super.clean();
  }

  @override
  FutureOr<void> refetchData({bool remember = false}) {
    return fetchData(
      refresh: false,
      remember: remember,
      preCall: () {
        clean();
        emitLoading();
      },
    );
  }

  @override
  FutureOr<void> refreshData({bool remember = false}) {
    return fetchData(refresh: true, remember: remember);
  }

  void _handleDataSource(Stream<Either<ResponseEntity, Input>> streamSource) {
    _streamSourceSubscription?.cancel();
    _streamSourceSubscription = streamSource.listen((event) {
      _handleSingleSource(event.asResult);
    });
  }

  FutureOr<void> _handleSingleSource(
      Result<Either<ResponseEntity, Input>> singleSource) async {
    final future = await singleSource.value;
    return future.fold(
      (l) {
        return injectInputState(Error(l));
      },
      (r) {
        return injectInput(r);
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

  void setupTimer() {
    if (state is Error && enableRetry) {
      if (retryInterval != null) {
        markNeedsRefresh(delay: retryInterval!);
      }
    } else if (state is Loaded<Output> &&
        enableRefresh &&
        hasData &&
        _canFetchData.value) {
      if (refreshInterval != null) {
        markNeedsRefresh(delay: refreshInterval!);
      }
    }
  }

  void markNeedsRefresh({Duration delay = Duration.zero}) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      final refetchOrRefresh = shouldRefetchOrRefresh.value ?? false;
      shouldRefetchOrRefresh.value = refetchOrRefresh || false;
      if (lastTrafficLightsValue) {
        _performMarkedRefresh();
      }
    });
  }

  void markNeedsRefetch({Duration delay = Duration.zero}) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      shouldRefetchOrRefresh.value = true;
      if (lastTrafficLightsValue) {
        _performMarkedRefresh();
      }
    });
  }

  void markNeedsRefetchOrRefresh({Duration delay = Duration.zero}) {
    if (refreshIsRefetch) {
      markNeedsRefetch(delay: delay);
    } else {
      markNeedsRefresh(delay: delay);
    }
  }

  FutureOr<void> _performMarkedRefresh() async {
    final refetchOrRefresh = shouldRefetchOrRefresh.value;
    if (refetchOrRefresh == null) return;
    _timer?.cancel();
    shouldRefetchOrRefresh.value = null;
    return refetchOrRefresh ? refetchData() : refreshData();
  }

  @override
  void onAppState(bool isActive) {
    super.onAppState(isActive);
    if (isActive && refreshOnAppActive && !refreshOnActive) {
      markNeedsRefetchOrRefresh();
    }
  }

  @override
  @mustCallSuper
  void trafficLightsChanged(bool green) {
    if (green) {
      _streamSourceSubscription?.resume();
      if (!_alreadyFetchedData.value) {
        fetchData();
      } else if (shouldRefetchOrRefresh.value != null) {
        _performMarkedRefresh();
      }
      if (refreshOnActive) {
        markNeedsRefetchOrRefresh();
      }
      if (_hasSingleSource) {
        setupTimer();
      }
    } else {
      _streamSourceSubscription?.pause();
    }
    super.trafficLightsChanged(green);
  }
}
