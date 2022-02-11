part of 'handlation.dart';

typedef _TriggerType<Data> = BaseCubit<Loaded<Data>>;

mixin TriggerHandlerMixin<Input, Output, State extends BlocState>
    on
        SourcesMixin<Input, Output, State>,
        OutputConverterMixin<Input, Output, State> {
  List<_TriggerType> get triggers;
  late final List<StreamSubscription> _subscriptions;

  final Map<Type, List<_TriggerState>> _triggers = {};
  final Map<_HandlerKey, _HandlerWrapper> _handlers = {};

  @override
  get sources => [...super.sources, ...triggers.map((e) => e.stream)];
  @override
  get subscriptions => super.subscriptions..addAll(_subscriptions);

  @override
  clean() {
    _triggers.clear();
    _handlers.values.forEach((element) => element.activate());
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
    return _handlers.remove(cookie._key) != null;
  }

  CookieJar onTriggerState<Data>(
    _TriggerType trigger, {
    _StateHandler<Data>? handler,
    _Handler<Input, Data>? inputHandler,
    _Handler<Output, Data>? outputHandler,
  }) {
    return _registerHandler<Data>(
        trigger.runtimeType, false, handler, inputHandler, outputHandler);
  }

  CookieJar onTrigger<Data>(
    _TriggerType<Data> trigger, {
    _StateHandler<Data>? handler,
    _Handler<Input, Data>? inputHandler,
    _Handler<Output, Data>? outputHandler,
  }) {
    return _registerHandler<Data>(
        trigger.runtimeType, true, handler, inputHandler, outputHandler);
  }

  CookieJar _registerHandler<Data>(
    Type trigger,
    bool general,
    _StateHandler<Data>? handler,
    _Handler<Input, Data>? inputHandler,
    _Handler<Output, Data>? outputHandler,
  ) {
    _HandlerKey? hk;
    _HandlerKey? ihk;
    _HandlerKey? ohk;
    if (handler != null) {
      hk = _HandlerKey.create(general, Null, Data, trigger);
      _handlers[hk] = _HandlerWrapper((output, trigger) => handler(trigger));
    }
    if (inputHandler != null) {
      ihk = _HandlerKey.general(Input, trigger);
      _handlers[ihk] =
          _HandlerWrapper((output, trigger) => inputHandler(output, trigger));
    }
    if (outputHandler != null) {
      ohk = _HandlerKey.general(Output, trigger);
      _handlers[ohk] =
          _HandlerWrapper((output, trigger) => outputHandler(output, trigger));
    }
    return CookieJar._(hk, ihk, ohk);
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
    final handler = _handlers[key];
    if (handler != null) {
      final result = await handler(source, trigger.data);
      if (result.isRemoveHandler) {
        handler.deactivate();
      }
      return result.isHandled;
    }
    final generalKey = _HandlerKey.general(T, triggerType);
    final generalHandler = _handlers[generalKey];
    if (generalHandler != null) {
      final result = await generalHandler(source, trigger.data);
      if (result.isRemoveHandler) {
        generalHandler.deactivate();
      }
      return result.isHandled;
    }
    return false;
  }
}
