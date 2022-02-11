import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_test/flutter_test.dart';

class Loaded<T> extends Equatable {
  final T data;
  const Loaded(this.data);
  @override
  get props => [data];
}

class Trigger<T> {
  Loaded<T> data;

  Trigger(T data) : data = Loaded(data);
}

typedef Output = String;

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
  get stringify => true;

  @override
  get props => [data, trigger];
}

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

void onTriggerState<Data>(Trigger trigger, _Handler<Output, Data> handler) {
  final key = _HandlerKey(Data, trigger.runtimeType);
  _handlers[key] = (output, trigger) => handler(output, trigger);
}

void onTrigger<Data>(Trigger<Data> trigger, _Handler<Output, Data> handler) {
  final key = _HandlerKey.general(trigger.runtimeType);
  _handlers[key] = (output, trigger) => handler(output, trigger);
}

final List<Trigger> triggers = [];
final Map<Type, List<_Trigger>> _triggers = {};
final Map<_HandlerKey, _Handler<Output, dynamic>> _handlers = {};

class A {}

class B extends A {}

class C extends A {}

class D extends C {}

Future<void> main() async {
  test("Trigger", () async {
    final Trigger<A> t1 = Trigger(A());
    final Trigger<A> t2 = Trigger(B());
    final Trigger<B> t3 = Trigger(B());
    final Trigger<C> t4 = Trigger(D());
    triggers.addAll([t1, t2, t3, t4]);
    triggers.forEach((trigger) {
      _triggers[trigger.runtimeType] ??= [];
      _triggers[trigger.runtimeType]!.add(_Trigger(trigger.data.data));
    });
    onTriggerState<A>(t1, (output, trigger) {
      print("A $trigger");
    });
    onTriggerState<B>(t1, (output, trigger) {
      print("B $trigger");
      return true;
    });
    onTriggerState<C>(t1, (output, trigger) {
      print("B $trigger");
      return true;
    });
    // onTrigger<int>(t2, (output, trigger) {
    //   print(trigger);
    //   return false;
    // });
    // onTrigger<double>(t3, (output, trigger) {
    //   print(trigger);
    //   return false;
    // });
    onTrigger<A>(t1, (output, trigger) {
      print("General $trigger");
      return true;
    });
    onTrigger<A>(t2, (output, trigger) {
      print("General $trigger");
      return true;
    });
    onTrigger<B>(t3, (output, trigger) {
      print("General $trigger");
      return true;
    });
    print(_triggers.values.map((value) => value.length));
    await handleOutputToInject("");
    print(_triggers.values.map((value) => value.length));
  });
}
