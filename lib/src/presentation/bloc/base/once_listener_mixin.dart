import 'dart:async';

import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:api_bloc_base/src/presentation/bloc/worker/worker_bloc.dart';
import 'package:rxdart/rxdart.dart';

mixin OnceListenerMixin<Data> on WorkerBloc<Data> {
  Map<Type, Stream> get streamSources;
  Map<Type, int> _wasCalled = {};
  Map<Type, StreamSubscription> _subs = {};

  void init() {
    setUpSourcesListeners();
    super.init();
  }

  void setUpSourcesListeners() {
    _subs = streamSources.map((type, value) => MapEntry(
        type,
        value
            .where((event) => event != null)
            .doOnData((event) => _wasCalled[type] ??= 1)
            .where((event) => (_wasCalled[type] ?? 1) > 0)
            .map((event) {
          _wasCalled[type] = _wasCalled[type]! - 1;
          return event;
        }).listen((event) => handleSourceData(type, event))));
  }

  void handleSourceData(Type type, event) {
    print("$type loaded");
  }

  @override
  Future<void> close() {
    _subs.forEach((key, value) => value.cancel());
    return super.close();
  }
}
