import 'dart:convert';

import 'package:api_bloc_base/src/presentation/screens/page.dart';
import 'package:api_bloc_base/src/presentation/screens/screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

abstract class RouteName {
  static const auto = AutoName();
  static const autoWithoutRoute = AutoNameWithOptions(withoutRoute: true);
  static const autoWithoutScreen = AutoNameWithOptions(withoutScreen: true);
  const RouteName._();

  String getName(RouteInfo route);
}

class AutoName extends RouteName {
  final Map<Pattern, String> replacements;
  const AutoName({this.replacements = const {}}) : super._();

  @override
  String getName(RouteInfo route) {
    final routeTypeName = route.runtimeType.toString();
    var routeName = routeTypeName;
    replacements.forEach((key, value) {
      routeName = routeName.replaceAll(key, value);
    });
    return routeName;
  }
}

class AutoNameWithOptions extends RouteName {
  final bool? withoutRoute;
  final bool? withoutScreen;
  final bool? ignoreCase;
  const AutoNameWithOptions({
    this.withoutRoute,
    this.withoutScreen,
    this.ignoreCase,
  }) : super._();

  @override
  String getName(RouteInfo route) {
    final routeTypeName = route.runtimeType.toString();
    var routeName = routeTypeName;
    final caseSensitive = ignoreCase != true;
    if (withoutRoute == true) {
      routeName = routeName.replaceAll(
          RegExp(r'Route$', caseSensitive: caseSensitive), '');
    }
    if (withoutScreen == true) {
      routeName = routeName.replaceAll(
          RegExp(r'Screen$', caseSensitive: caseSensitive), '');
    }
    return routeName;
  }
}

class ManualName extends RouteName {
  final String name;
  const ManualName(this.name) : super._();

  @override
  String getName(RouteInfo route) {
    return name;
  }
}

class RouteParameters {
  final Uri uri;
  final RouteSettings settings;
  final PlatformRouteType routeType;
  final bool fullscreenDialog;

  const RouteParameters({
    required this.uri,
    required this.settings,
    required this.routeType,
    required this.fullscreenDialog,
  });
}

enum PlatformRouteType { material, cupertino, adaptive }

abstract class RouteInfo<T, A extends RouteArguments> {
  static const RouteZeroArguments noArgs = RouteZeroArguments();
  final RouteName _name;
  final ArgumentFactory<A> _argumentsFactory;
  final PlatformRouteType routeType;
  final bool fullscreenDialog;

  String get name => _name.getName(this);

  const RouteInfo(
    this._name,
    this._argumentsFactory, {
    this.routeType = PlatformRouteType.material,
    this.fullscreenDialog = false,
  });

  @protected
  IPageScreen<RouteInfo<T, A>> build(BuildContext context, A argument);

  Type get resultType => T;

  bool canBeResult(dynamic data) {
    return data is T?;
  }

  dynamic parseArgument(String parameter) {
    final integer = int.tryParse(parameter);
    if (integer != null) return integer;
    final floating = double.tryParse(parameter);
    if (floating != null) return floating;
    if (parameter == 'true') return true;
    if (parameter == 'false') return false;
    return jsonDecode(parameter);
  }

  Map<String, dynamic> fixQuery(Map<String, List<String>> query) {
    return query.map((key, value) {
      dynamic newValue;

      if (value.isEmpty) {
        newValue = null;
      } else if (value.length == 1) {
        newValue = parseArgument(value.first);
      } else {
        newValue = value.map(parseArgument).toList();
      }

      return MapEntry(key, newValue);
    });
  }

  Route<T> buildRoute({
    required Uri uri,
    required RouteSettings settings,
    PlatformRouteType? routeType,
    bool? fullscreenDialog,
  }) {
    A routeArgs;
    final args = settings.arguments;
    if (args is A) {
      routeArgs = args;
    } else {
      final json = fixQuery(uri.queryParametersAll);
      routeArgs = _argumentsFactory.fromMap(json);
    }
    return buildPageRoute(
      RouteParameters(
        uri: uri,
        settings: settings,
        routeType: routeType ?? this.routeType,
        fullscreenDialog: fullscreenDialog ?? this.fullscreenDialog,
      ),
      routeArgs,
    );
  }

  Route<T> buildPageRoute(RouteParameters params, A arguments) {
    final builder = () {
      if (params.routeType == PlatformRouteType.cupertino ||
          (params.routeType == PlatformRouteType.adaptive &&
              (UniversalPlatform.isIOS || UniversalPlatform.isMacOS))) {
        return CupertinoPageResultRoute.new;
      } else {
        return MaterialPageResultRoute.new;
      }
    }();
    return builder(
      builder: (context) {
        return build(context, arguments);
      },
      route: this,
      params: params,
      arguments: arguments,
      settings: params.settings,
      fullscreenDialog: params.fullscreenDialog,
    );
  }

  String createUri(A argument) {
    final query = argument.toJson();
    return Uri(
      path: name,
      queryParameters: query.map(
        (key, value) {
          if (value is num || value is String || value is bool) {
            return MapEntry(key, value.toString());
          } else {
            try {
              return MapEntry(key, jsonEncode(value));
            } catch (_) {
              return MapEntry(key, null);
            }
          }
        },
      )..removeWhere((key, value) => value == null),
    ).toString();
  }

  void pop(BuildContext context, {required T result}) {
    return Navigator.pop(context, result);
  }

  void popSaved(BuildContext context, {T? result}) {
    result = stateOf(context).currentResult;
    return pop(context, result: result!);
  }

  Future<bool> maybePop(BuildContext context, {required T result}) {
    return Navigator.maybePop(context, result);
  }

  Future<bool> maybePopSaved(BuildContext context, {T? result}) {
    result = stateOf(context).currentResult;
    return maybePop(context, result: result!);
  }

  Future<T?> pushClearTop<R>(
    BuildContext context, {
    required A argument,
    R? result,
  }) async {
    if (result != null) {
      await Navigator.maybePop(context, result);
    }
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      createUri(argument),
      (route) => false,
      arguments: argument,
    );
  }

  Future<T?> push(BuildContext context, {required A argument}) {
    return Navigator.pushNamed<T>(
      context,
      createUri(argument),
      arguments: argument,
    );
  }

  Future<T?> replace<R>(
    BuildContext context, {
    required A argument,
    R? result,
    bool? popAndPush,
  }) {
    final action = () {
      if (popAndPush == true) {
        return Navigator.popAndPushNamed;
      } else {
        return Navigator.pushReplacementNamed;
      }
    }();
    return action<T, R>(
      context,
      createUri(argument),
      arguments: argument,
      result: result,
    );
  }

  Future<T?> refresh(
    BuildContext context, {
    T? result,
    bool? popAndPush,
  }) {
    final argument = this(context).arguments;
    return replace<T>(
      context,
      argument: argument,
      result: result,
      popAndPush: popAndPush,
    );
  }

  ScreenRoute<T, A> call(BuildContext context) {
    return stateOf(context);
  }

  ScreenRoute<T, A> stateOf(BuildContext context) {
    return ScreenRoute.of(context);
  }

  static Route? maybeOf<Route extends RouteInfo>(BuildContext context) {
    final route = ScreenRoute.maybeOf(context)?.route;
    if (route is Route) {
      return route;
    }
    return null;
  }

  static Route of<Route extends RouteInfo>(BuildContext context) {
    return maybeOf<Route>(context)!;
  }
}

mixin NoResultRouteMixin on RouteInfo<void, RouteZeroArguments> {
  @override
  void pop(BuildContext context, {void result}) {
    return super.pop(context, result: null);
  }

  @override
  Future<bool> maybePop(BuildContext context, {required void result}) {
    return super.maybePop(context, result: null);
  }
}

abstract class NoArgumentsRouteInfo<T>
    extends RouteInfo<T, RouteZeroArguments> {
  const NoArgumentsRouteInfo(RouteName name)
      : super(
          name,
          const RouteZeroArgumentsFactory(),
        );

  @override
  @protected
  IPageScreen<NoArgumentsRouteInfo<T>> build(
    BuildContext context, [
    RouteZeroArguments? argument = RouteInfo.noArgs,
  ]);

  @override
  Future<T?> pushClearTop<R>(
    BuildContext context, {
    RouteZeroArguments argument = RouteInfo.noArgs,
    R? result,
  }) {
    return super.pushClearTop(context, argument: argument, result: result);
  }

  @override
  Future<T?> push(
    BuildContext context, {
    RouteZeroArguments argument = RouteInfo.noArgs,
  }) {
    return super.push(context, argument: argument);
  }

  @override
  Future<T?> replace<R>(
    BuildContext context, {
    RouteZeroArguments argument = RouteInfo.noArgs,
    R? result,
    bool? popAndPush,
  }) {
    return super.replace(context, argument: argument, result: result);
  }
}

abstract class RouteArguments<T> {
  Map<String, dynamic> toJson();
}

abstract class ArgumentFactory<T> {
  T fromMap(Map<String, dynamic> map);
}

class RouteZeroArguments implements RouteArguments<RouteZeroArguments> {
  const RouteZeroArguments();

  @override
  Map<String, dynamic> toJson() {
    return {};
  }
}

class RouteZeroArgumentsFactory implements ArgumentFactory<RouteZeroArguments> {
  const RouteZeroArgumentsFactory();
  @override
  RouteZeroArguments fromMap(Map<String, dynamic> map) {
    return RouteInfo.noArgs;
  }
}

class RouteArgument<X> implements RouteArguments<RouteArgument<X>> {
  final X arg;
  final String name;
  const RouteArgument(this.arg, {this.name = 'arg'});
  @override
  Map<String, dynamic> toJson() {
    return {name: arg};
  }
}

class RouteArgumentFactory<X> implements ArgumentFactory<RouteArgument<X>> {
  final String name;
  const RouteArgumentFactory({this.name = 'arg'});
  @override
  RouteArgument<X> fromMap(Map<String, dynamic> map) {
    return RouteArgument(map[name]);
  }
}

abstract class Json {
  Map<String, dynamic> toJson();
}

typedef Factory<J extends Json> = J Function(Map<String, dynamic> json);

abstract class JsonArgument<T> implements RouteArguments<T>, Json {}

class JsonArgumentFactory<A extends JsonArgument<A>>
    implements ArgumentFactory<A> {
  final Factory<A> creator;
  const JsonArgumentFactory(this.creator);
  @override
  A fromMap(Map<String, dynamic> map) {
    return creator(map);
  }
}

class SimpleArgument<A extends Json>
    implements RouteArguments<SimpleArgument<A>> {
  final A arg;
  const SimpleArgument(this.arg);
  @override
  Map<String, dynamic> toJson() {
    return arg.toJson();
  }
}

class SimpleArgumentFactory<A extends Json>
    implements ArgumentFactory<SimpleArgument<A>> {
  final A Function(Map<String, dynamic> json) creator;
  const SimpleArgumentFactory(this.creator);
  @override
  SimpleArgument<A> fromMap(Map<String, dynamic> map) {
    return SimpleArgument<A>(creator(map));
  }
}

class MapArgument implements RouteArguments<MapArgument> {
  final Map<String, dynamic> arg;
  const MapArgument(this.arg);
  @override
  Map<String, dynamic> toJson() {
    return arg;
  }
}

class RouteMapArgumentFactory implements ArgumentFactory<MapArgument> {
  const RouteMapArgumentFactory();
  @override
  MapArgument fromMap(Map<String, dynamic> map) {
    return MapArgument(map);
  }
}
