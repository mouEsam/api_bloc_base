import 'package:api_bloc_base/src/presentation/screens/page.dart';
import 'package:api_bloc_base/src/presentation/screens/route.dart';
import 'package:flutter/widgets.dart';

abstract class IPageScreen<Route extends RouteInfo> implements Widget {}

extension RouteScreenUtils<T, A extends RouteArguments,
    Route extends RouteInfo<T, A>> on IPageScreen<Route> {
  Route getRoute(BuildContext context) {
    return RouteInfo.of<Route>(context);
  }

  ScreenRoute<T, A> getRouteState(BuildContext context) {
    final info = ScreenRoute.of<T, A>(context);
    return info;
  }
}
