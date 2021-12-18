import 'dart:async';

import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:rxdart/rxdart.dart';

mixin OnceListenerMixin<Data> on WorkerMixin<Data> {
  Map<Type, Stream> get streamSources;
  Map<Type, int> _wasCalled = {};
  Map<Type, StreamSubscription> _subs = {};

  void init() {
    setUpSourcesListeners();
    super.init();
  }

  bool _init = false;
  void setUpSourcesListeners() {
    if (_init) return;
    _init = true;
    _subs = streamSources.map((type, value) => MapEntry(
        type,
        value
            .where((event) => event != null)
            .doOnData((event) => _wasCalled[type] ??= 1)
            .where((event) => (_wasCalled[type] ?? 1) > 0)
            .listen((event) {
          final listened = handleSourceData(type, event);
          if (listened) {
            _wasCalled[type] = _wasCalled[type]! - 1;
          }
        })));
  }

  bool handleSourceData(Type type, event) {
    print("$type loaded");
    return true;
  }

  @override
  Future<void> close() {
    _subs.forEach((key, value) => value.cancel());
    return super.close();
  }
}
