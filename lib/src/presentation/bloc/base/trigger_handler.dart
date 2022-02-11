import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/input_to_output.dart';
import 'package:equatable/equatable.dart';

import 'sources_mixin.dart';
import 'state.dart';

typedef TriggerType<Data> = BaseCubit<Loaded<Data>>;

typedef _StateHandler<Data> = FutureOr<bool?> Function(Data trigger);
typedef _Handler<Output, Data> = FutureOr<bool?> Function(
    Output output, Data trigger);

class _TriggerState<T> extends Equatable {
  final Type type;
  final T data;

  _TriggerState(this.data) : type = data.runtimeType;

  @override
  get props => [type, data];
}

class _HandlerKey extends Equatable {
  final Type source;
  final Type data;
  final Type trigger;

  const _HandlerKey(this.source, this.data, this.trigger);

  const _HandlerKey.general(this.source, this.trigger) : data = Null;

  @override
  get props => [source, data, trigger];
}

mixin TriggerHandlerMixin<Input, Output, State extends BlocState>
    on
        SourcesMixin<Input, Output, State>,
        OutputConverterMixin<Input, Output, State> {
  List<TriggerType> get triggers;
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

  void onTriggerState<Data>(
    TriggerType trigger, {
    _StateHandler<Data>? handler,
    _Handler<Input, Data>? inputHandler,
    _Handler<Output, Data>? outputHandler,
  }) {
    if (handler != null) {
      final key = _HandlerKey(Null, Data, trigger.runtimeType);
      _handlers[key] = (output, trigger) => handler(trigger);
    }
    if (inputHandler != null) {
      final key = _HandlerKey(Input, Data, trigger.runtimeType);
      _handlers[key] = (output, trigger) => inputHandler(output, trigger);
    }
    if (outputHandler != null) {
      final key = _HandlerKey(Output, Data, trigger.runtimeType);
      _handlers[key] = (output, trigger) => outputHandler(output, trigger);
    }
  }

  void onTrigger<Data>(
    TriggerType<Data> trigger, {
    _StateHandler<Data>? handler,
    _Handler<Input, Data>? inputHandler,
    _Handler<Output, Data>? outputHandler,
  }) {
    if (handler != null) {
      final key = _HandlerKey.general(Null, trigger.runtimeType);
      _handlers[key] = (output, trigger) => handler(trigger);
    }
    if (inputHandler != null) {
      final key = _HandlerKey.general(Input, trigger.runtimeType);
      _handlers[key] = (output, trigger) => inputHandler(output, trigger);
    }
    if (outputHandler != null) {
      final key = _HandlerKey.general(Output, trigger.runtimeType);
      _handlers[key] = (output, trigger) => outputHandler(output, trigger);
    }
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
      Type triggerType, T source, _TriggerState trigger) {
    final key = _HandlerKey(T, trigger.type, triggerType);
    final handler = _handlers[key];
    if (handler != null) {
      return handler(source, trigger.data);
    }
    final generalKey = _HandlerKey.general(T, triggerType);
    final generalHandler = _handlers[generalKey];
    if (generalHandler != null) {
      return generalHandler(source, trigger.data);
    }
    return false;
  }
}
