import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'route.dart';
import 'screen.dart';

typedef ScreenPageBuilder<Route extends RouteInfo> = IPageScreen<Route>
    Function(BuildContext context);

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
    required ScreenPageBuilder<Route> builder,
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
    required ScreenPageBuilder<Route> builder,
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

class MaterialDialogResultRoute<T, A extends RouteArguments,
        Route extends RouteInfo<T, A>> extends DialogRoute<T>
    with ScreenRouteMixin<T, A> {
  @override
  final Uri uri;
  @override
  final A arguments;
  @override
  final Route route;
  final T? defaultResult;

  MaterialDialogResultRoute._({
    required BuildContext context,
    required ScreenPageBuilder<Route> builder,
    required this.arguments,
    required this.uri,
    required this.route,
    this.defaultResult,
    RouteSettings? settings,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
  }) : super(
          context: context,
          builder: builder,
          barrierDismissible: barrierDismissible,
          barrierColor: barrierColor,
          barrierLabel: barrierLabel,
          settings: settings,
        );

  factory MaterialDialogResultRoute({
    required BuildContext context,
    required ScreenPageBuilder<Route> builder,
    required A arguments,
    required Uri uri,
    required Route route,
    T? defaultResult,
    RouteSettings? settings,
    bool barrierDismissible = true,
    bool rootNavigator = true,
    Color? barrierColor,
    String? barrierLabel,
  }) {
    final CapturedThemes themes = InheritedTheme.capture(
      from: context,
      to: Navigator.of(
        context,
        rootNavigator: rootNavigator,
      ).context,
    );
    return MaterialDialogResultRoute._(
      context: context,
      builder: builder,
      arguments: arguments,
      uri: uri,
      route: route,
      defaultResult: defaultResult,
      settings: settings,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      barrierLabel: barrierLabel,
    );
  }
}

class CupertinoDialogResultRoute<T, A extends RouteArguments,
        Route extends RouteInfo<T, A>> extends CupertinoDialogRoute<T>
    with ScreenRouteMixin<T, A> {
  @override
  final Uri uri;
  @override
  final A arguments;
  @override
  final Route route;
  final T? defaultResult;

  CupertinoDialogResultRoute({
    required BuildContext context,
    required ScreenPageBuilder<Route> builder,
    required this.arguments,
    required this.uri,
    required this.route,
    this.defaultResult,
    RouteSettings? settings,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
  }) : super(
          context: context,
          builder: builder,
          barrierDismissible: barrierDismissible,
          barrierColor: barrierColor,
          barrierLabel: barrierLabel,
          settings: settings,
        );
}

abstract class ScreenRoute<T, A extends RouteArguments>
    implements ModalRoute<T> {
  Uri get uri;
  A get arguments;
  RouteInfo<T, A> get route;

  void setResult(T? result, {bool? updateState});
  bool canBeResult(dynamic data);

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

mixin ScreenRouteMixin<T, A extends RouteArguments> on ModalRoute<T>
    implements ScreenRoute<T, A> {
  @override
  bool canBeResult(dynamic data) => route.canBeResult(data);

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
