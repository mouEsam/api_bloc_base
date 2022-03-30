import 'package:api_bloc_base/src/presentation/screens/page.dart';
import 'package:api_bloc_base/src/presentation/screens/route.dart';
import 'package:flutter/widgets.dart';

abstract class IPageScreen<Route extends RouteInfo> implements Widget {}

extension RouteScreenUtils<T, A extends RouteArguments,
    Route extends RouteInfo<T, A>> on IPageScreen<Route> {
  Route getRoute(BuildContext context) {
    return RouteInfo.of<Route>(context);
  }

  RouteScreenState<T, A> getRouteState(BuildContext context) {
    final info = RouteScreen.of<T, A>(context);
    return info;
  }
}

class RouteScope extends InheritedWidget {
  const RouteScope({
    Key? key,
    required this.route,
    required this.screen,
  }) : super(key: key, child: screen);

  final RouteScreen screen;
  final RouteInfo route;

  @override
  bool updateShouldNotify(oldWidget) {
    return false;
  }
}

class ScreenScope extends InheritedWidget {
  const ScreenScope({
    Key? key,
    required this.screenState,
    required IPageScreen screen,
    required this.result,
  }) : super(key: key, child: screen);

  final RouteScreenState screenState;
  final dynamic result;

  @override
  bool updateShouldNotify(ScreenScope oldWidget) {
    return result != oldWidget.result;
  }
}

class RouteScreen<T, A extends RouteArguments> extends StatefulWidget {
  const RouteScreen({
    Key? key,
    required this.params,
    required this.screen,
    required this.arguments,
    this.defaultResult,
  }) : super(key: key);

  final RouteParameters params;
  final IPageScreen screen;
  final A arguments;
  final T? defaultResult;

  @override
  State<RouteScreen> createState() => RouteScreenState<T, A>();

  static RouteScreenState<T, A>? maybeOf<T, A extends RouteArguments>(
      BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ScreenScope>()
        ?.screenState as RouteScreenState<T, A>?;
  }

  static RouteScreenState<T, A> of<T, A extends RouteArguments>(
      BuildContext context) {
    return maybeOf<T, A>(context)!;
  }
}

class RouteScreenState<T, A extends RouteArguments>
    extends State<RouteScreen<T, A>> {
  RouteParameters get params => widget.params;
  A get argument => widget.arguments;
  T? _result;
  T? get result => _result;

  set result(T? result) {
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      if (mounted) {
        PageRouteScope.of<T>(context).setResult(result);
        setState(() {
          _result = result;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _result = widget.defaultResult;
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScope(
      screenState: this,
      result: _result,
      screen: widget.screen,
    );
  }
}
