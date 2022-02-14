import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:listenable_stream/listenable_stream.dart';
import 'package:rxdart/rxdart.dart';

enum _NavEventType { Add, Remove }

class _NavEvent {
  final _NavEventType type;
  final Route route;

  const _NavEvent(this.type, this.route);
}

abstract class Compass implements NavigatorObserver {
  Route? get currentRoute;
  FutureOr<Route> awaitRoute(RoutePredicate predicate);
  FutureOr<Route> awaitAdded(RoutePredicate predicate);
  FutureOr<Route> awaitRemoved(RoutePredicate predicate);
}

class CompassNavigatorObserver extends NavigatorObserver implements Compass {
  final _currentRoute = ValueNotifier<Route?>(null);
  final _currentEvent = ValueNotifier<_NavEvent?>(null);

  Route? get currentRoute => _currentRoute.value;

  FutureOr<Route> awaitRoute(RoutePredicate predicate) {
    return _currentRoute
        .toValueStream(replayValue: true)
        .whereType<Route>()
        .firstWhere(predicate);
  }

  FutureOr<Route> awaitAdded(RoutePredicate predicate) {
    return _awaitEvent(predicate, _NavEventType.Add);
  }

  FutureOr<Route> awaitRemoved(RoutePredicate predicate) {
    return _awaitEvent(predicate, _NavEventType.Remove);
  }

  FutureOr<Route> _awaitEvent(RoutePredicate predicate, _NavEventType type) {
    return _currentEvent
        .toValueStream(replayValue: true)
        .whereType<_NavEvent>()
        .where((event) => event.type == type)
        .map((event) => event.route)
        .firstWhere(predicate);
  }

  @override
  @mustCallSuper
  void didPop(Route route, Route? previousRoute) {
    _currentRoute.value = previousRoute;
    _currentEvent.value = _NavEvent(_NavEventType.Remove, route);
    didChange(previousRoute, route);
  }

  @override
  @mustCallSuper
  void didPush(Route route, Route? previousRoute) {
    _currentRoute.value = route;
    _currentEvent.value = _NavEvent(_NavEventType.Add, route);
    didChange(previousRoute, route);
  }

  @override
  @mustCallSuper
  void didRemove(Route route, Route? previousRoute) {
    _currentRoute.value = previousRoute;
    _currentEvent.value = _NavEvent(_NavEventType.Remove, route);
    didChange(previousRoute, route);
  }

  @override
  @mustCallSuper
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _currentRoute.value = newRoute;
    if (oldRoute != null) {
      _currentEvent.value = _NavEvent(_NavEventType.Remove, oldRoute);
    }
    if (newRoute != null) {
      _currentEvent.value = _NavEvent(_NavEventType.Add, newRoute);
    }
    didChange(oldRoute, newRoute);
  }

  void didChange(Route? from, Route? to) {}

  @override
  void didStartUserGesture(Route route, Route? previousRoute) {}

  @override
  void didStopUserGesture() {}
}
