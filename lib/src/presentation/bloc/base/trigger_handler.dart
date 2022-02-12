part of 'handlation.dart';

typedef _TriggerType<Data> = BaseCubit<Loaded<Data>>;

mixin TriggerHandlerMixin<Input, Output, State extends BlocState>
    on
        SourcesMixin<Input, Output, State>,
        OutputConverterMixin<Input, Output, State> {
  List<_TriggerType> get triggers;
  late final List<StreamSubscription> _subscriptions;

  final Map<Type, List<_TriggerState>> _triggers = {};
  final Map<_HandlerKey, List<_HandlerWrapper>> _handlers = {};

  @override
  get sources => [...super.sources, ...triggers.map((e) => e.stream)];
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
      return trigger.exclusiveStream.listen((event) async {
        _triggers[trigger.runtimeType] ??= [];
        final state = _TriggerState(event.data);
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

  CookieJar onTriggerState<Data>(
    _TriggerType trigger, {
    _StateHandler<Data>? handler,
    _Handler<Input, Data>? inputHandler,
    _Handler<Output, Data>? outputHandler,
  }) {
    return _registerHandlers<Data>(
        trigger.runtimeType, false, handler, inputHandler, outputHandler);
  }

  CookieJar onTrigger<Data>(
    _TriggerType<Data> trigger, {
    _StateHandler<Data>? handler,
    _Handler<Input, Data>? inputHandler,
    _Handler<Output, Data>? outputHandler,
  }) {
    return _registerHandlers<Data>(
        trigger.runtimeType, true, handler, inputHandler, outputHandler);
  }

  CookieJar _registerHandlers<Data>(
    Type trigger,
    bool general,
    _StateHandler<Data>? handler,
    _Handler<Input, Data>? inputHandler,
    _Handler<Output, Data>? outputHandler,
  ) {
    _HandlerWrapper? hk;
    _HandlerWrapper? ihk;
    _HandlerWrapper? ohk;
    if (handler != null) {
      hk = _registerHandler<Null, Data>(
          trigger, general, (output, trigger) => handler(trigger));
    }
    if (inputHandler != null) {
      ihk = _registerHandler<Input, Data>(
          trigger, general, (output, trigger) => inputHandler(output, trigger));
    }
    if (outputHandler != null) {
      ohk = _registerHandler<Output, Data>(trigger, general,
          (output, trigger) => outputHandler(output, trigger));
    }
    return CookieJar._(hk, ihk, ohk);
  }

  _HandlerWrapper _registerHandler<Source, Data>(
    Type trigger,
    bool general,
    _Handler<Source, Data> handler,
  ) {
    final h = _HandlerWrapper.wrap<Source, Data>(general, trigger, handler);
    _handlers[h.key] ??= [];
    _handlers[h.key]!.add(h);
    return h;
  }

  @override
  FutureOr<void> handleInjectedInput(input) async {
    await _handleStates<Input>(input);
    return super.handleInjectedInput(input);
  }

  @override
  FutureOr<void> handleOutputToInject(output) async {
    await _handleStates<Output>(output);
    return super.handleOutputToInject(output);
  }

  FutureOr<void> _handleStates<T>(T data) async {
    for (final trigger in _triggers.entries) {
      final key = trigger.key;
      final value = trigger.value;
      List toRemove = [];
      for (int i = 0; i < value.length; i++) {
        final item = value[i];
        final handled = _handleTrigger<T>(key, data, item);
        if (handled is bool?) {
          if (handled == true) {
            toRemove.add(item);
          }
        } else if (true == await handled) {
          toRemove.add(item);
        }
      }
      toRemove.forEach(value.remove);
    }
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
