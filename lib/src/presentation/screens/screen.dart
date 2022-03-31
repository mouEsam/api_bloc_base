import 'package:flutter/widgets.dart';

import 'page.dart';
import 'route.dart';

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

  void setResult(BuildContext context, T? result) {
    getRouteState(context).setResult(result);
  }

  bool hasResult(BuildContext context) {
    return getRoute(context).hasResult(context);
  }
}
