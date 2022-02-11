import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/input_to_output.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/_index.dart';
import 'package:equatable/equatable.dart';

import 'sources_mixin.dart';
import 'state.dart';

typedef _Handler<Output, Data> = FutureOr<bool?> Function(
    Output output, Data trigger);

class _Trigger<T> extends Equatable {
  final Type type;
  final T data;

  _Trigger(this.data) : type = data.runtimeType;

  @override
  get props => [type, data];
}

class _HandlerKey extends Equatable {
  final Type data;
  final Type trigger;

  const _HandlerKey(this.data, this.trigger);

  const _HandlerKey.general(this.trigger) : data = Null;

  static _HandlerKey create<Data, TriggerType>() {
    return _HandlerKey(Data, TriggerType);
  }

  @override
  get props => [data, trigger];
}

mixin TriggerHandlerMixin<Input, Output, State extends BlocState>
    on
        SourcesMixin<Input, Output, State>,
        OutputInjectorMixin<Input, Output, State> {
  List<Trigger> get triggers;
  late final List<StreamSubscription> _subscriptions;

  final Map<Type, List<_Trigger>> _triggers = {};
  final Map<_HandlerKey, _Handler<Output, dynamic>> _handlers = {};

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
      return trigger.exclusiveStream.listen((event) {
        _triggers[trigger.runtimeType] ??= [];
        _triggers[trigger.runtimeType]!.add(_Trigger(event.data));
      });
    }).toList();
  }

  void onTrigger<Data>(Trigger trigger, _Handler<Output, Data> handler) {
    final key = _HandlerKey(Data, trigger.runtimeType);
    _handlers[key] = (output, trigger) => handler(output, trigger);
  }

  void onGeneral<Data>(Trigger<Data> trigger, _Handler<Output, Data> handler) {
    final key = _HandlerKey.general(trigger.runtimeType);
    _handlers[key] = (output, trigger) => handler(output, trigger);
  }

  @override
  FutureOr<void> handleOutputToInject(output) async {
    for (final trigger in _triggers.entries) {
      final key = trigger.key;
      final value = trigger.value;
      List toRemove = [];
      for (final item in value) {
        if (true == await _handleTrigger(key, output, item)) {
          toRemove.add(item);
        }
      }
      toRemove.forEach(value.remove);
    }
  }

  FutureOr<bool?> _handleTrigger(
      Type triggerType, Output output, _Trigger trigger) {
    final key = _HandlerKey(trigger.type, triggerType);
    final handler = _handlers[key];
    if (handler != null) {
      return handler(output, trigger.data);
    }
    final generalKey = _HandlerKey.general(triggerType);
    final generalHandler = _handlers[generalKey];
    if (generalHandler != null) {
      return generalHandler(output, trigger.data);
    }
    return false;
  }
}
