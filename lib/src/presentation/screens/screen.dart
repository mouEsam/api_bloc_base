import 'package:api_bloc_base/src/presentation/screens/route.dart';
import 'package:flutter/widgets.dart';

abstract class IPageScreen<Route extends RouteInfo> implements Widget {}

extension RouteScreenUtils<T, A extends RouteArguments,
    Route extends RouteInfo<T, A>> on IPageScreen<Route> {
  Route getRoute(BuildContext context) {
    return RouteInfo.of<Route>(context);
  }

  ScreenRouteInfo<A> getRouteInfo(BuildContext context) {
    final info = ScreenRouteInfo.of<A>(context);
    return info;
  }
}

class ScreenRouteInfo<A extends RouteArguments> {
  final RouteParameters params;
  final A argument;

  const ScreenRouteInfo(this.params, this.argument);

  static ScreenRouteInfo<A>? maybeOf<A extends RouteArguments>(
      BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ScreenScope>()?.routeInfo
        as ScreenRouteInfo<A>?;
  }

  static ScreenRouteInfo<A> of<A extends RouteArguments>(BuildContext context) {
    return maybeOf<A>(context)!;
  }
}

class RouteScope extends InheritedWidget {
  const RouteScope({
    Key? key,
    required this.route,
    required ScreenScope screen,
  }) : super(key: key, child: screen);

  final RouteInfo route;

  @override
  bool updateShouldNotify(oldWidget) {
    return false;
  }
}

class ScreenScope extends InheritedWidget {
  const ScreenScope({
    Key? key,
    required this.routeInfo,
    required IPageScreen screen,
  }) : super(key: key, child: screen);

  final ScreenRouteInfo routeInfo;

  @override
  bool updateShouldNotify(oldWidget) {
    return false;
  }
}
