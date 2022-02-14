import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/navigation/compass.dart';
import 'package:api_bloc_base/src/presentation/bloc/navigation/sailor_bloc.dart';
import 'package:flutter/cupertino.dart';

import 'action_state.dart';

class NavigationHandler extends BaseCubit<Loaded<ActionState>> {
  final Sailor _sailor;
  Compass get compass => _sailor.compass;

  NavigationHandler(this._sailor) : super(Loaded(NoActionState()));

  void loadDoneState(ActionDoneState state) {
    emit(Loaded(state));
  }

  Future<R?> loadAction<S extends ActionDoneState, R>(
      NavigationActionState<S, R> state) {
    emit(Loaded(state));
    return handleAction<S, R>(state);
  }

  Future<R?> handleAction<S extends ActionDoneState, R>(
      NavigationActionState<S, R> state) async {
    final currentRoute = compass.currentRoute;
    _sailor.push(state.routeName, args: state.args);
    final route =
        await compass.awaitAdded(ModalRoute.withName(state.routeName));
    final result = await Future.any([
      awaitState<Loaded<S>>((s) => state.doneState(s.data))
          .then((s) => state.extractResult(s.data)),
      route.popped.then((value) => value is R ? value : null),
    ]);
    if (state.returnWhenDone) {
      final rName = currentRoute?.settings.name;
      if (rName != null) {
        _sailor.popUntil(ModalRoute.withName(rName));
      }
    }
    return result;
  }
}
