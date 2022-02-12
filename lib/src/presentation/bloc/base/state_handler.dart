part of 'handlation.dart';

typedef _SourceType = BaseCubit<BlocState>;

mixin StateHandlerMixin<Output, State extends BlocState>
    on StatefulBloc<Output, State> {
  List<_SourceType> get triggers;
  late final List<StreamSubscription> _subscriptions;

  final Map<Type, List<_TriggerState>> _triggers = {};
  final Map<_HandlerKey, List<_HandlerWrapper>> _handlers = {};
  final Map<_HandlerKey, int> _handlersCount = {};

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

  init() {
    initializeTriggers();
    super.init();
  }

  bool _init = false;
  void initializeTriggers() {
    if (_init) {
      return;
    }
    _init = true;
    _subscriptions = triggers.map((trigger) {
      return trigger.exclusiveStream
          .where((event) => _hasHandler(event.runtimeType, trigger.runtimeType))
          .listen((event) async {
        _triggers[trigger.runtimeType] ??= [];
        final state = _TriggerState(event);
        final list = _triggers[trigger.runtimeType]!;
        list.add(state);
        final handled = _handleTrigger<Null>(trigger.runtimeType, null, state);
        if (handled is bool?) {
          if (handled == true) {
            list.remove(state);
          }
        } else if (true == await handled) {
          list.remove(state);
        }
      });
    }).toList();
  }

  bool _hasHandler(Type data, Type trigger) {
    final key = _HandlerKey.noSource(data, trigger);
    final spec = _handlersCount[key];
    if (spec != null && spec > 0) {
      return true;
    }
    final gen = _handlersCount[key.generalized];
    if (gen != null && gen > 0) {
      return true;
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
      final handler = handlers!.removeAt(hIndex);
      if (handler._active) {
        final g = key.unSourced;
        _handlersCount[g] = _handlersCount[g]! - 1;
      }
      return true;
    }
    return false;
  }

  Cookie onTriggerState<Data>(
      _SourceType trigger, _StateHandler<Data> handler) {
    return _registerHandler<Data>(trigger.runtimeType, false, handler);
  }

  Cookie onTrigger<Data>(_SourceType trigger, _StateHandler<Data> handler) {
    return _registerHandler<Data>(trigger.runtimeType, true, handler);
  }

  Cookie _registerHandler<Data>(
      Type trigger,
      bool general,
      _StateHandler<Data> handler,
      ) {
    final h = _HandlerWrapper.wrap<Null, Data>(general, trigger, (output, trigger) => handler(trigger),
            (key, active) {
          final g = key.unSourced;
          _handlersCount[g] = _handlersCount[g]! + (active ? 1 : -1);
        });
    _handlers[h.key] ??= [];
    _handlers[h.key]!.add(h);
    final g = h.key.unSourced;
    _handlersCount[g] = (_handlersCount[g] ?? 0) + 1;
    return Cookie._forHandler(h);
  }

  FutureOr<bool?> _handleTrigger<T>(
      Type triggerType, T source, _TriggerState trigger) async {
    final key = _HandlerKey(T, trigger.type, triggerType);
    final handlers = _handlers[key]?.where((element) => element._active);
    if (handlers != null && handlers.isNotEmpty) {
      return _handleTriggerState<T>(handlers, source, trigger);
    }
    final generalKey = _HandlerKey.general(T, triggerType);
    final generalHandlers =
        _handlers[generalKey]?.where((element) => element._active);
    if (generalHandlers != null && generalHandlers.isNotEmpty) {
      return _handleTriggerState<T>(generalHandlers, source, trigger);
    }
    return false;
  }

  FutureOr<bool?> _handleTriggerState<T>(Iterable<_HandlerWrapper> handlers,
      T source, _TriggerState trigger) async {
    bool isHandled = false;
    for (final handler in handlers) {
      final result = await handler(source, trigger.data);
      if (result.isRemoveHandler) {
        _removeHandler(handler.key, handler.index);
      }
      if (result.isDeactivateHandler) {
        handler.deactivate();
      }
      isHandled = isHandled || result.isHandled;
    }
    return isHandled;
  }
}
