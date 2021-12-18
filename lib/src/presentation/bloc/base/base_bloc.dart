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

  List<ChangeNotifier> get notifiers => [];
  List<Timer?> get timers => [];
  List<StreamSubscription?> get subscriptions => [];
  List<StreamSink> get sinks => [];
  List<Subject> get subjects => [];

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

  @override
  Future<void> close() async {
    notifiers.forEach((element) {
      try {
        element.dispose();
      } catch (e) {
        print(e);
      }
    });
    timers.forEach((element) {
      try {
        element?.cancel();
      } catch (e) {
        print(e);
      }
    });
    subscriptions.forEach((element) {
      try {
        element?.cancel();
      } catch (e) {
        print(e);
      }
    });
    sinks.forEach((element) {
      try {
        element.close();
      } catch (e) {
        print(e);
      }
    });
    for (final subject in subjects) {
      try {
        await subject.drain().then((value) => subject.close());
      } catch (e) {
        print(e);
      }
    }
    return super.close();
  }
}
