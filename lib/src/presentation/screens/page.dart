import 'package:api_bloc_base/src/presentation/screens/route.dart';
import 'package:api_bloc_base/src/presentation/screens/screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

typedef ScreenBuilder<Route extends RouteInfo> = IPageScreen<Route> Function(
    BuildContext context);

class MaterialPageResultRoute<T, A extends RouteArguments,
        Route extends RouteInfo<T, A>> extends MaterialPageRoute<T>
    with ScreenRouteMixin<T, A> {
  @override
  final Uri uri;
  @override
  final A arguments;
  @override
  final Route route;
  final T? defaultResult;

  MaterialPageResultRoute({
    required ScreenBuilder<Route> builder,
    required this.arguments,
    required this.uri,
    required this.route,
    this.defaultResult,
    String? title,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) : super(
          builder: builder,
          settings: settings,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
        );
}

class CupertinoPageResultRoute<T, A extends RouteArguments,
        Route extends RouteInfo<T, A>> extends CupertinoPageRoute<T>
    with ScreenRouteMixin<T, A> {
  @override
  final Uri uri;
  @override
  final A arguments;
  @override
  final Route route;
  final T? defaultResult;

  CupertinoPageResultRoute({
    required ScreenBuilder<Route> builder,
    required this.arguments,
    required this.uri,
    required this.route,
    this.defaultResult,
    String? title,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) : super(
          builder: builder,
          settings: settings,
          title: title,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
        );
}

abstract class ScreenRoute<T, A extends RouteArguments>
    implements PageRoute<T> {
  Uri get uri;
  A get arguments;
  RouteInfo<T, A> get route;

  void setResult(T? result, {bool? updateState});

  static ScreenRoute<T, A>? maybeOf<T, A extends RouteArguments>(
      BuildContext context) {
    final route = ModalRoute.of(context);
    if (route is ScreenRoute<T, A>) {
      return route;
    }
    return null;
  }

  static ScreenRoute<T, A> of<T, A extends RouteArguments>(
      BuildContext context) {
    return ScreenRoute.maybeOf<T, A>(context)!;
  }
}

mixin ScreenRouteMixin<T, A extends RouteArguments> on PageRoute<T>
    implements ScreenRoute<T, A> {
  T? _result;
  @override
  void setResult(T? result, {bool? updateState}) {
    _result = result;
    if (updateState == true) {
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
        setState(() {});
      });
    }
  }

  @override
  T? get currentResult => _result;
}
