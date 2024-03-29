part of 'handlation.dart';

typedef _SourceType = BaseCubit<BlocState>;

mixin StateHandlerMixin<Output, State extends BlocState>
    on StatefulBloc<Output, State> {
  bool get handleStatesSequentially => false;

  HandlerAction get defaultHandlerAction => HandlerAction.Handled;

  List<_SourceType> get triggers;

  late final List<StreamSubscription> _subscriptions;

  final Map<Type, List<_TriggerState>> _triggers = {};
  final Map<_HandlerKey, List<_HandlerWrapper>> _handlers = {};

  @override
  get subscriptions => super.subscriptions..addAll(_subscriptions);

  @override
  clean() {
    _triggers.clear();
    _handlers.values.forEach(
      (list) => list.forEach(
        (element) => element.activate(),
      ),
    );
    super.clean();
  }

  bool _init = false;
  @override
  void init() {
    if (_init) return;
    _init = true;
    _initializeTriggers();
    super.init();
  }

  void _initializeTriggers() {
    _subscriptions = triggers.map((trigger) {
      return trigger.coldStream
          .map((event) => _TriggerState(event))
          .where((state) => _hasHandler(state, trigger.runtimeType))
          .listen((state) async {
        _triggers[trigger.runtimeType] ??= [];
        final list = _triggers[trigger.runtimeType]!;
        list.add(state);
        await _handleTriggers<Null>(trigger.runtimeType, list, null);
      });
    }).toList();
  }

  bool _hasHandler(_TriggerState trigger, Type triggerType) {
    final sources = [Output, Null];
    for (final source in sources) {
      final key = _HandlerKey(source, triggerType);
      final spec = _handlers[key];
      if (spec != null && spec.any((element) => element.canHandle(trigger))) {
        return true;
      }
    }
    return false;
  }

  bool removeHandler(Cookie cookie) {
    return _removeHandler(cookie._key, cookie._index);
  }

  bool _removeHandler(_HandlerKey key, int index) {
    final handlers = _handlers[key];
    final hIndex = handlers?.indexWhere((element) => element.index == index);
    if (hIndex != null && hIndex > -1) {
      handlers!.removeAt(hIndex);
      return true;
    }
    return false;
  }

  Cookie onSourceState<Data>(
    _SourceType source,
    _StateHandler<Data> handler, [
    bool Function(Data)? predicate,
  ]) {
    return _registerHandler<Data>(source.runtimeType, handler, predicate);
  }

  Cookie onLoadedState<Data>(
    _SourceType source,
    _StateHandler<Data> handler, [
    bool Function(Data)? predicate,
  ]) {
    return _registerHandler<Loaded<Data>>(
      source.runtimeType,
      (state) => handler(state.data),
      (state) {
        return predicate?.call(state.data) ?? true;
      },
    );
  }

  Cookie _registerHandler<Data>(
    Type trigger,
    _StateHandler<Data> handler,
    bool Function(Data)? predicate,
  ) {
    predicate ??= (_) => true;
    final h = _HandlerWrapper.wrap<Null, Data>(
        trigger, (output, trigger) => handler(trigger), (stateData) {
      return stateData is Data && predicate!(stateData);
    });
    _handlers[h.key] ??= [];
    _handlers[h.key]!.add(h);
    return Cookie._forHandler(h);
  }

  void clearRemainingStates() {
    _triggers.clear();
  }

  FutureOr<void> handleRemainingStates() async {
    for (final trigger in _triggers.entries) {
      final key = trigger.key;
      final value = trigger.value;
      await _handleTriggers<Null>(key, value, null);
    }
  }

  FutureOr<void> _handleTriggers<T>(
      Type triggerType, List<_TriggerState> triggers, T source) {
    if (handleStatesSequentially) {
      return _handleTriggersSequentially<T>(triggerType, triggers, source);
    } else {
      return _handleTriggersConcurrently<T>(triggerType, triggers, source);
    }
  }

  FutureOr<void> _handleTriggersSequentially<T>(
      Type triggerType, List<_TriggerState> triggers, T source) async {
    final List<_TriggerState> toRemove = [];
    final futures = triggers.map((item) async {
      final handled = _handleTrigger<T>(triggerType, source, item);
      if (handled is bool?) {
        if (handled == true) {
          toRemove.add(item);
        }
      } else if (true == await handled) {
        toRemove.add(item);
      }
    });
    await Future.wait(futures);
    toRemove.forEach(triggers.remove);
  }

  FutureOr<void> _handleTriggersConcurrently<T>(
      Type triggerType, List<_TriggerState> triggers, T source) async {
    final List<_TriggerState> toRemove = [];
    for (final item in triggers.toList()) {
      final handled = _handleTrigger<T>(triggerType, source, item);
      if (handled is bool?) {
        if (handled == true) {
          toRemove.add(item);
        }
      } else if (true == await handled) {
        toRemove.add(item);
      }
    }
    toRemove.forEach(triggers.remove);
  }

  FutureOr<bool?> _handleTrigger<T>(
      Type triggerType, T source, _TriggerState state) async {
    final key = _HandlerKey(T, triggerType);
    final handlers =
        _handlers[key]?.where((element) => element.canHandle(state)).toList();
    if (handlers != null && handlers.isNotEmpty) {
      final exact =
          handlers.where((element) => element.data == state.type).toList();
      if (exact.isNotEmpty) {
        return _handleTriggerState<T>(exact, source, state);
      }
      final remaining =
          handlers.where((element) => element.data != state.type).toList();
      if (remaining.isNotEmpty) {
        return _handleTriggerState<T>(remaining, source, state);
      }
    }
    return false;
  }

  FutureOr<bool?> _handleTriggerState<T>(Iterable<_HandlerWrapper> handlers,
      T source, _TriggerState trigger) async {
    if (await trigger.isHandled) {
      return true;
    }
    final Completer<bool> _isHandled = Completer();
    return trigger.setHandled(() async {
      bool isHandled = false;
      for (final handler in handlers) {
        final result =
            await handler(source, trigger.data) ?? defaultHandlerAction;
        if (result.isHandled) {
          trigger.addDoneHandler(handler.index);
        }
        if (result.isRemoveHandler) {
          _removeHandler(handler.key, handler.index);
        }
        if (result.isDeactivateHandler) {
          handler.deactivate();
        }
        isHandled = isHandled || result.isRemoveEvent;
      }
      _isHandled.complete(isHandled);
      return isHandled;
    });
  }
}
