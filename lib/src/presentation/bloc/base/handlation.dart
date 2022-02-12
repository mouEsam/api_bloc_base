import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/input_to_output.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/stateful_bloc.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/traffic_lights_mixin.dart';
import 'package:equatable/equatable.dart';

import 'base_bloc.dart';
import 'sources_mixin.dart';
import 'state.dart';

part 'state_handler.dart';
part 'trigger_handler.dart';

typedef _HandlerResult = FutureOr<HandlerAction?>;
typedef _StateHandler<Data> = _HandlerResult Function(Data trigger);
typedef _Handler<Output, Data> = _HandlerResult Function(
    Output output, Data trigger);

class _TriggerState<T> {
  final Type type;
  final T data;
  final List<int> doneHandlers = [];

  Completer<bool> _handle = Completer()..complete(false);
  bool _isHandled = false;
  bool _isBeingHandled = false;
  _TriggerState(this.data) : type = data.runtimeType;

  FutureOr<bool> get isHandled => _handle.future;

  FutureOr<bool> setHandled([FutureOr<bool> Function()? isHandled]) async {
    _handle = Completer();
    _isBeingHandled = true;
    final handled = isHandled?.call();
    bool temp;
    if (handled == null) {
      temp = true;
    } else if (handled is bool) {
      temp = handled;
    } else {
      temp = await handled;
    }
    _isBeingHandled = false;
    if (!_handle.isCompleted) {
      _handle.complete(temp);
    }
    _isHandled = temp;
    return _isHandled;
  }

  void addDoneHandler(int index) {
    doneHandlers.add(index);
  }

  bool isDone(int index) {
    return doneHandlers.contains(index);
  }
}

class CookieJar {
  final Cookie? handlerCookie;
  final Cookie? inputHandlerCookie;
  final Cookie? outputHandlerCookie;

  CookieJar._(
    _HandlerWrapper? handlerKey,
    _HandlerWrapper? inputHandlerKey,
    _HandlerWrapper? outputHandlerKey,
  )   : handlerCookie = _createCookie(handlerKey),
        inputHandlerCookie = _createCookie(inputHandlerKey),
        outputHandlerCookie = _createCookie(outputHandlerKey);

  static Cookie? _createCookie(_HandlerWrapper? handler) {
    return handler == null ? null : Cookie._forHandler(handler);
  }
}

class Cookie {
  final _HandlerKey _key;
  final int _index;

  const Cookie._(this._key, this._index);

  factory Cookie._forHandler(_HandlerWrapper handler) {
    return Cookie._(handler.key, handler.index);
  }
}

enum HandlerAction {
  Handled,
  // ignore: unused_field
  Unhandled,
  RemoveEvent,
  RemoveEventRemoveHandler,
  RemoveEventDeactivateHandler,
  RemoveHandler,
  DeactivateHandler,
  HandledRemoveHandler,
  UnhandledRemoveHandler,
  HandledDeactivateHandler,
  UnhandledDeactivateHandler,
}

extension on HandlerAction? {
  bool get isRemoveEvent => [
        HandlerAction.RemoveEvent,
        HandlerAction.RemoveEventRemoveHandler,
        HandlerAction.RemoveEventDeactivateHandler,
      ].contains(this);
  bool get isHandled => [
        HandlerAction.Handled,
        HandlerAction.HandledRemoveHandler
      ].contains(this);
  bool get isRemoveHandler => [
        HandlerAction.RemoveHandler,
        HandlerAction.RemoveEventRemoveHandler,
        HandlerAction.HandledRemoveHandler,
        HandlerAction.UnhandledRemoveHandler
      ].contains(this);
  bool get isDeactivateHandler => [
        HandlerAction.DeactivateHandler,
        HandlerAction.RemoveEventDeactivateHandler,
        HandlerAction.HandledDeactivateHandler,
        HandlerAction.UnhandledDeactivateHandler,
      ].contains(this);
}

class _HandlerKey extends Equatable {
  final Type source;
  final Type data;
  final Type trigger;

  _HandlerKey(this.source, this.data, this.trigger);

  _HandlerKey.general(this.source, this.trigger) : data = Null;
  _HandlerKey.noSource(this.data, this.trigger) : source = Null;

  factory _HandlerKey.create(
      bool general, Type source, Type data, Type trigger) {
    return _HandlerKey(source, general ? Null : data, trigger);
  }

  _HandlerKey get unSourced => _HandlerKey.noSource(data, trigger);
  _HandlerKey get generalized => _HandlerKey.general(source, trigger);

  @override
  get props => [source, data, trigger];
}

class _HandlerWrapper<Source, Data> {
  static int _index = 0; // no need to synchronise
  final _HandlerKey key;
  final _Handler<Source, Data> _handler;
  final int index = _index++;
  final void Function(_HandlerKey key, bool active) _onStateChanged;
  bool _active = true;

  _HandlerWrapper._(this.key, this._handler, this._onStateChanged);

  static _HandlerWrapper<Source, Data> wrap<Source, Data>(
    bool general,
    Type trigger,
    _Handler<Source, Data> _handler,
    void Function(_HandlerKey key, bool active) onStateChanged,
  ) {
    final key = _HandlerKey.create(general, Source, Data, trigger);
    return _HandlerWrapper._(key, _handler, onStateChanged);
  }

  void deactivate() {
    if (_active) {
      _active = false;
      _onStateChanged(key, _active);
    }
  }

  void activate() {
    if (!_active) {
      _active = true;
      _onStateChanged(key, _active);
    }
  }

  _HandlerResult call(Source output, Data trigger) => _handler(output, trigger);

  bool canHandle(_TriggerState state) {
    return _active && !state.isDone(index);
  }
}
