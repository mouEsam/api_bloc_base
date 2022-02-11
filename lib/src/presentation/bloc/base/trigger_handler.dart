import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/input_to_output.dart';
import 'package:equatable/equatable.dart';

import 'sources_mixin.dart';
import 'state.dart';

typedef TriggerType<Data> = BaseCubit<Loaded<Data>>;

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
      return trigger.exclusiveStream.listen((event) {
        _triggers[trigger.runtimeType] ??= [];
        _triggers[trigger.runtimeType]!.add(_TriggerState(event.data));
      });
    }).toList();
  }

  void onTriggerState<Data>(
    TriggerType trigger, {
    _Handler<Input, Data>? inputHandler,
    _Handler<Output, Data>? outputHandler,
  }) {
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
    _Handler<Input, Data>? inputHandler,
    _Handler<Output, Data>? outputHandler,
  }) {
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
    for (final trigger in _triggers.entries) {
      final key = trigger.key;
      final value = trigger.value;
      List toRemove = [];
      for (final item in value) {
        if (true == await _handleTrigger<Input>(key, input, item)) {
          toRemove.add(item);
        }
      }
      toRemove.forEach(value.remove);
    }
    super.handleInjectedInput(input);
  }

  @override
  FutureOr<void> handleOutputToInject(output) async {
    for (final trigger in _triggers.entries) {
      final key = trigger.key;
      final value = trigger.value;
      List toRemove = [];
      for (final item in value) {
        if (true == await _handleTrigger<Output>(key, output, item)) {
          toRemove.add(item);
        }
      }
      toRemove.forEach(value.remove);
    }
    super.handleOutputToInject(output);
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
