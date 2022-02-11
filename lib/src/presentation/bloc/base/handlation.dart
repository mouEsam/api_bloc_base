import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/input_to_output.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/stateful_bloc.dart';
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
  RemoveHandler,
  DeactivateHandler,
  HandledRemoveHandler,
  UnhandledRemoveHandler,
  HandledDeactivateHandler,
  UnhandledDeactivateHandler,
}

extension on HandlerAction? {
  bool get isHandled => [
        HandlerAction.Handled,
        HandlerAction.HandledRemoveHandler
      ].contains(this);
  bool get isRemoveHandler => [
        HandlerAction.RemoveHandler,
        HandlerAction.HandledRemoveHandler,
        HandlerAction.UnhandledRemoveHandler
      ].contains(this);
  bool get isDeactivateHandler => [
        HandlerAction.DeactivateHandler,
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

  factory _HandlerKey.create(
      bool general, Type source, Type data, Type trigger) {
    return _HandlerKey(source, general ? Null : data, trigger);
  }

  @override
  get props => [source, data, trigger];
}

class _HandlerWrapper<Source, Data> {
  static int _index = 0;
  final _HandlerKey key;
  final _Handler<Source, Data> _handler;
  final int index = _index++;
  bool _active = true;

  _HandlerWrapper._(this.key, this._handler);

  static _HandlerWrapper<Source, Data> wrap<Source, Data>(
    bool general,
    Type trigger,
    _Handler<Source, Data> _handler,
  ) {
    final key = _HandlerKey.create(general, Source, Data, trigger);
    return _HandlerWrapper._(key, _handler);
  }

  void deactivate() => _active = false;
  void activate() => _active = true;

  _HandlerResult call(Source output, Data trigger) => _handler(output, trigger);
}
