part of 'handlation.dart';

typedef _SourceType = BaseCubit<BlocState>;

mixin StateHandlerMixin<Output, State extends BlocState>
    on StatefulBloc<Output, State> {
  List<_SourceType> get triggers;
  late final List<StreamSubscription> _subscriptions;

  final Map<Type, List<_TriggerState>> _triggers = {};
  final Map<_HandlerKey, _Handler> _handlers = {};

  @override
  get subscriptions => super.subscriptions..addAll(_subscriptions);

  @override
  clean() {
    _triggers.clear();
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

  bool removeHandler(Cookie cookie) {
    return _handlers.remove(cookie._key) != null;
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
    final hk = _HandlerKey.create(general, Null, Data, trigger);
    _handlers[hk] = (output, trigger) => handler(trigger);
    return Cookie._(hk);
  }

  FutureOr<bool?> _handleTrigger<T>(
      Type triggerType, T source, _TriggerState trigger) async {
    final key = _HandlerKey(T, trigger.type, triggerType);
    final handler = _handlers[key];
    if (handler != null) {
      final result = await handler(source, trigger.data);
      if (result.isRemoveHandler) {
        _handlers.remove(key);
      }
      return result.isHandled;
    }
    final generalKey = _HandlerKey.general(T, triggerType);
    final generalHandler = _handlers[generalKey];
    if (generalHandler != null) {
      final result = await generalHandler(source, trigger.data);
      if (result.isRemoveHandler) {
        _handlers.remove(generalKey);
      }
      return result.isHandled;
    }
    return false;
  }
}
