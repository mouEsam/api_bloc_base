import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/input_to_output.dart';
import 'package:equatable/equatable.dart';

import 'sources_mixin.dart';
import 'state.dart';

typedef _TriggerType<Data> = BaseCubit<Loaded<Data>>;
typedef HandlerResult = FutureOr<HandlerState?>;
typedef _StateHandler<Data> = HandlerResult Function(Data trigger);
typedef _Handler<Output, Data> = HandlerResult Function(
    Output output, Data trigger);

mixin TriggerHandlerMixin<Input, Output, State extends BlocState>
    on
        SourcesMixin<Input, Output, State>,
        OutputConverterMixin<Input, Output, State> {
  List<_TriggerType> get triggers;
  late final List<StreamSubscription> _subscriptions;

  final Map<Type, List<_TriggerState>> _triggers = {};
  final Map<_HandlerKey, _Handler> _handlers = {};

  @override
  get sources => [...super.sources, ...triggers.map((e) => e.stream)];
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
      _handlers[hk] = (output, trigger) => handler(trigger);
    }
    if (inputHandler != null) {
      ihk = _HandlerKey.general(Input, trigger);
      _handlers[ihk] = (output, trigger) => inputHandler(output, trigger);
    }
    if (outputHandler != null) {
      ohk = _HandlerKey.general(Output, trigger);
      _handlers[ohk] = (output, trigger) => outputHandler(output, trigger);
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

class _TriggerState<T> extends Equatable {
  final Type type;
  final T data;

  _TriggerState(this.data) : type = data.runtimeType;

  @override
  get props => [type, data];
}

class CookieJar {
  final Cookie? handlerCookie;
  final Cookie? inputHandlerCookie;
  final Cookie? outputHandlerCookie;

  CookieJar._(
    _HandlerKey? handlerKey,
    _HandlerKey? inputHandlerKey,
    _HandlerKey? outputHandlerKey,
  )   : handlerCookie = _createCookie(handlerKey),
        inputHandlerCookie = _createCookie(inputHandlerKey),
        outputHandlerCookie = _createCookie(outputHandlerKey);

  static Cookie? _createCookie(_HandlerKey? handlerKey) {
    return handlerKey == null ? null : Cookie(handlerKey);
  }
}

class Cookie {
  final _HandlerKey _key;

  const Cookie(this._key);
}

enum HandlerState {
  Handled,
  // ignore: unused_field
  Unhandled,
  HandledRemoveHandler,
  UnhandledRemoveHandler,
}

extension on HandlerState? {
  bool get isHandled =>
      [HandlerState.Handled, HandlerState.HandledRemoveHandler].contains(this);
  bool get isRemoveHandler => [
        HandlerState.HandledRemoveHandler,
        HandlerState.UnhandledRemoveHandler
      ].contains(this);
}

class _HandlerKey extends Equatable {
  final Type source;
  final Type data;
  final Type trigger;

  const _HandlerKey(this.source, this.data, this.trigger);

  const _HandlerKey.general(this.source, this.trigger) : data = Null;

  factory _HandlerKey.create(
      bool general, Type source, Type data, Type trigger) {
    return _HandlerKey(source, general ? Null : data, trigger);
  }

  @override
  get props => [source, data, trigger];
}
