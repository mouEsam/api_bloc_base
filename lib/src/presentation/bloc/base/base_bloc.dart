import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

import 'initializable.dart';

abstract class BaseCubit<State> extends Cubit<State> implements Initializable {
  BaseCubit(State initialState) : super(initialState) {
    init();
  }

  Stream<State> get exclusiveStream => super.stream;

  @override
  get stream => super.stream.shareValueSeeded(state).map((e) => state);

  Set<ChangeNotifier> get notifiers => {};
  Set<Timer?> get timers => {};
  Set<StreamSubscription?> get subscriptions => {};
  Set<StreamSink> get sinks => {};
  Set<Subject> get subjects => {};

  @override
  void init() {}

  @override
  @mustCallSuper
  void onChange(change) {
    super.onChange(change);
    stateChanged(change.nextState);
    print("${this.runtimeType} emitting ${change.nextState}");
  }

  void stateChanged(State nextState) {}

  Future<S> awaitState<S extends State>([bool Function(S state)? f]) {
    f ??= (_) => true;
    return stream.whereType<S>().firstWhere(f);
  }

Future<S> nextState<S extends State>([bool Function(S state)? f]) {
    f ??= (_) => true;
    return exclusiveStream.whereType<S>().firstWhere(f);
  }

  Future<R> whenState<S extends State, R extends Object?>(
      [FutureOr<R> Function()? f]) {
    f ??= () => Future.value(null);
    return exclusiveStream
        .firstWhere((event) => event is S)
        .then((value) => f!());
  }

  @override
  Future<void> close() async {
    notifiers.forEach((element) {
      try {
        element.dispose();
      } catch (e, s) {
        print(e);
        print(s);
      }
    });
    timers.forEach((element) {
      try {
        element?.cancel();
      } catch (e, s) {
        print(e);
        print(s);
      }
    });
    subscriptions.forEach((element) {
      try {
        element?.cancel();
      } catch (e, s) {
        print(e);
        print(s);
      }
    });
    sinks.forEach((element) {
      try {
        element.close();
      } catch (e, s) {
        print(e);
        print(s);
      }
    });
    for (final subject in subjects) {
      try {
        await subject.drain().then((value) => subject.close());
      } catch (e, s) {
        print(e);
        print(s);
      }
    }
    return super.close();
  }
}
