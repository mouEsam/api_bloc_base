import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'page.dart';
import 'screen.dart';
import 'package:universal_platform/universal_platform.dart';

abstract class RouteName {
  const RouteName._();

  const factory RouteName.autoReplace({
    Type? type,
    Map<Pattern, String> replacements,
  }) = AutoName._;

  const factory RouteName.auto({
    Type? type,
    bool? withoutRoute,
    bool? withoutScreen,
    bool? withoutDialog,
    bool? ignoreCase,
  }) = AutoNameWithOptions._;

  const factory RouteName.trim({
    Type? type,
    bool? withoutRoute,
    bool? withoutScreen,
    bool? withoutDialog,
    bool? ignoreCase,
  }) = AutoNameWithOptions._trim;

  const factory RouteName.withoutRoute({
    Type? type,
    bool? ignoreCase,
  }) = AutoNameWithOptions._withoutRoute;

  const factory RouteName.withoutScreen({
    Type? type,
    bool? ignoreCase,
  }) = AutoNameWithOptions._withoutScreen;

  const factory RouteName.withoutDialog({
    Type? type,
    bool? ignoreCase,
  }) = AutoNameWithOptions._withoutDialog;

  const factory RouteName(String name) = ManualName.new;

  String getName(RouteInfo route);
}

class AutoName extends RouteName {
  final Type? type;
  final Map<Pattern, String> replacements;
  const AutoName._({this.type, this.replacements = const {}}) : super._();

  @override
  String getName(RouteInfo route) {
    final type = this.type ?? route.runtimeType;
    final routeTypeName = type.toString();
    var routeName = routeTypeName;
    replacements.forEach((key, value) {
      routeName = routeName.replaceAll(key, value);
    });
    return routeName;
  }
}

class AutoNameWithOptions extends RouteName {
  final Type? type;
  final bool? withoutRoute;
  final bool? withoutScreen;
  final bool? withoutDialog;
  final bool? ignoreCase;

  const AutoNameWithOptions._({
    this.type,
    this.withoutRoute,
    this.withoutScreen,
    this.withoutDialog,
    this.ignoreCase,
  }) : super._();

  const AutoNameWithOptions._withoutRoute({
    this.type,
    this.ignoreCase,
  })  : withoutRoute = true,
        withoutScreen = null,
        withoutDialog = null,
        super._();

  const AutoNameWithOptions._withoutScreen({
    this.type,
    this.ignoreCase,
  })  : withoutScreen = true,
        withoutRoute = null,
        withoutDialog = null,
        super._();

  const AutoNameWithOptions._withoutDialog({
    this.type,
    this.ignoreCase,
  })  : withoutDialog = true,
        withoutScreen = null,
        withoutRoute = null,
        super._();

  const AutoNameWithOptions._trim({
    this.type,
    this.ignoreCase,
    this.withoutRoute = true,
    this.withoutDialog = true,
    this.withoutScreen = true,
  }) : super._();

  @override
  String getName(RouteInfo route) {
    final type = this.type ?? route.runtimeType;
    final routeTypeName = type.toString();
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
    if (withoutDialog == true) {
      routeName = routeName.replaceAll(
          RegExp(r'Dialog$', caseSensitive: caseSensitive), '');
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
  final bool? fullscreenDialog;
  final bool? barrierDismissible;
  final Color? barrierColor;
  final String? barrierLabel;

  const RouteParameters({
    required this.uri,
    required this.settings,
    required this.routeType,
    this.fullscreenDialog,
    this.barrierDismissible,
    this.barrierColor,
    this.barrierLabel,
  });
}

enum PlatformRouteType { material, cupertino, adaptive }

abstract class RouteInfo<T, A extends RouteArguments> {
  static const RouteZeroArguments noArgs = RouteZeroArguments();
  final RouteName _name;
  final ArgumentFactory<A> _argumentsFactory;
  final PlatformRouteType routeType;
  final bool fullscreenDialog;
  final bool isDialog;
  final bool? barrierDismissible;
  final Color? barrierColor;
  final String? barrierLabel;

  String get name => _name.getName(this);

  const RouteInfo(
    this._name,
    this._argumentsFactory, {
    this.routeType = PlatformRouteType.material,
    this.fullscreenDialog = false,
    this.isDialog = false,
    this.barrierDismissible,
    this.barrierColor,
    this.barrierLabel,
  });

  const factory RouteInfo.builder({
    required RouteName name,
    required ArgumentFactory<A> argumentsFactory,
    required ScreenBuilder<T, A> builder,
    PlatformRouteType routeType,
    bool fullscreenDialog,
    bool isDialog,
  }) = RouteInfoBuilder._;

  const factory RouteInfo.simple({
    required RouteName name,
    required ArgumentFactory<A> argumentsFactory,
    required SimpleScreenBuilder<T, A> screen,
    PlatformRouteType routeType,
    bool fullscreenDialog,
    bool isDialog,
  }) = SimpleRouteInfo._;

  const factory RouteInfo.argument({
    required RouteName name,
    required ArgumentFactory<A> argumentsFactory,
    required SimpleArgumentScreenBuilder<T, A> screen,
    PlatformRouteType routeType,
    bool fullscreenDialog,
    bool isDialog,
  }) = SimpleArgumentRouteInfo._;

  @protected
  IPageScreen<RouteInfo<T, A>> build(BuildContext context, A arguments);

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

  Route<T> buildDialog(
    BuildContext context, {
    required Uri uri,
    required RouteSettings settings,
    PlatformRouteType? routeType,
    bool? barrierDismissible,
    Color? barrierColor,
    String? barrierLabel,
  }) {
    A routeArgs;
    final args = settings.arguments;
    if (args is A) {
      routeArgs = args;
    } else {
      final json = fixQuery(uri.queryParametersAll);
      routeArgs = _argumentsFactory.fromMap(json);
    }
    return buildDialogRoute(
      context,
      RouteParameters(
        uri: uri,
        settings: settings,
        routeType: routeType ?? this.routeType,
        barrierDismissible: barrierDismissible ?? this.barrierDismissible,
        barrierColor: barrierColor ?? this.barrierColor,
        barrierLabel: barrierLabel ?? this.barrierLabel,
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
      uri: params.uri,
      arguments: arguments,
      settings: params.settings,
      fullscreenDialog: params.fullscreenDialog ?? fullscreenDialog,
    );
  }

  Route<T> buildDialogRoute(
    BuildContext context,
    RouteParameters params,
    A arguments,
  ) {
    final builder = () {
      if (params.routeType == PlatformRouteType.cupertino ||
          (params.routeType == PlatformRouteType.adaptive &&
              (UniversalPlatform.isIOS || UniversalPlatform.isMacOS))) {
        return CupertinoDialogResultRoute.new;
      } else {
        return MaterialDialogResultRoute.new;
      }
    }();
    return builder(
      context: context,
      builder: (context) {
        return build(context, arguments);
      },
      route: this,
      uri: params.uri,
      arguments: arguments,
      settings: params.settings,
      barrierColor: params.barrierColor,
      barrierLabel: params.barrierLabel,
      barrierDismissible: params.barrierDismissible ?? true,
    );
  }

  Uri createUri(A argument) {
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
    );
  }

  void pop(BuildContext context, {required T result}) {
    return Navigator.pop(context, result);
  }

  void popSaved(BuildContext context, {T? result}) {
    result = stateOf(context).currentResult;
    return pop(context, result: result as T);
  }

  Future<bool> maybePop(BuildContext context, {required T result}) {
    return Navigator.maybePop(context, result);
  }

  Future<bool> maybePopSaved(BuildContext context, {T? result}) {
    result = stateOf(context).currentResult;
    return maybePop(context, result: result as T);
  }

  Future<T?> pushClearTop<R>(
    BuildContext context, {
    required A arguments,
    R? result,
  }) async {
    if (result != null) {
      await Navigator.maybePop(context, result);
    }
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      createUri(arguments).toString(),
      (route) => false,
      arguments: arguments,
    );
  }

  Future<T?> push(BuildContext context, {required A arguments}) {
    if (isDialog) {
      return Navigator.push<T>(
        context,
        buildDialog(
          context,
          uri: createUri(arguments),
          settings: RouteSettings(
            arguments: arguments,
          ),
        ),
      );
    } else {
      return Navigator.pushNamed<T>(
        context,
        createUri(arguments).toString(),
        arguments: arguments,
      );
    }
  }

  Future<T?> replace<R>(
    BuildContext context, {
    required A arguments,
    R? result,
    bool? popAndPush,
  }) {
    if (isDialog) {
      return _replaceDialog<R>(
        context,
        arguments: arguments,
        result: result,
      );
    } else {
      return _replacePage<R>(
        context,
        arguments: arguments,
        result: result,
        popAndPush: popAndPush,
      );
    }
  }

  Future<T?> _replacePage<R>(
    BuildContext context, {
    required A arguments,
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
      createUri(arguments).toString(),
      arguments: arguments,
      result: result,
    );
  }

  Future<T?> _replaceDialog<R>(
    BuildContext context, {
    required A arguments,
    R? result,
  }) {
    return Navigator.pushReplacement<T, R>(
      context,
      buildDialog(
        context,
        uri: createUri(arguments),
        settings: RouteSettings(
          arguments: arguments,
        ),
      ),
      result: result,
    );
  }

  Future<T?> refresh(
    BuildContext context, {
    T? result,
    bool? popAndPush,
  }) {
    final arguments = this(context).arguments;
    return replace<T>(
      context,
      arguments: arguments,
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
  const NoArgumentsRouteInfo(
    RouteName name, {
    PlatformRouteType routeType = PlatformRouteType.material,
    bool fullscreenDialog = false,
    bool isDialog = false,
  }) : super(
          name,
          const RouteZeroArgumentsFactory(),
          routeType: routeType,
          fullscreenDialog: fullscreenDialog,
          isDialog: isDialog,
        );

  const factory NoArgumentsRouteInfo.builder({
    required RouteName name,
    required NoArgumentScreenBuilder<T> builder,
    PlatformRouteType routeType,
    bool fullscreenDialog,
    bool isDialog,
  }) = NoArgumentRouteInfoBuilder._;

  const factory NoArgumentsRouteInfo.simple({
    required RouteName name,
    required ZeroArgumentScreenBuilder<T> screen,
    PlatformRouteType routeType,
    bool fullscreenDialog,
    bool isDialog,
  }) = SimpleNoArgumentRouteInfo._;

  @override
  @protected
  IPageScreen<NoArgumentsRouteInfo<T>> build(
    BuildContext context, [
    RouteZeroArguments? arguments = RouteInfo.noArgs,
  ]);

  @override
  Future<T?> pushClearTop<R>(
    BuildContext context, {
    RouteZeroArguments arguments = RouteInfo.noArgs,
    R? result,
  }) {
    return super.pushClearTop(context, arguments: arguments, result: result);
  }

  @override
  Future<T?> push(
    BuildContext context, {
    RouteZeroArguments arguments = RouteInfo.noArgs,
  }) {
    return super.push(context, arguments: arguments);
  }

  @override
  Future<T?> replace<R>(
    BuildContext context, {
    RouteZeroArguments arguments = RouteInfo.noArgs,
    R? result,
    bool? popAndPush,
  }) {
    return super.replace(context, arguments: arguments, result: result);
  }
}

typedef ScreenBuilder<T, A extends RouteArguments>
    = IPageScreen<RouteInfo<T, A>> Function(
  BuildContext context,
  A argument,
);

class RouteInfoBuilder<T, A extends RouteArguments> extends RouteInfo<T, A> {
  final ScreenBuilder<T, A> builder;

  const RouteInfoBuilder._({
    required RouteName name,
    required ArgumentFactory<A> argumentsFactory,
    required this.builder,
    PlatformRouteType routeType = PlatformRouteType.material,
    bool fullscreenDialog = false,
    bool isDialog = false,
  }) : super(
          name,
          argumentsFactory,
          routeType: routeType,
          fullscreenDialog: fullscreenDialog,
          isDialog: isDialog,
        );

  @override
  IPageScreen<RouteInfo<T, A>> build(BuildContext context, A arguments) {
    return builder(context, arguments);
  }
}

typedef SimpleScreenBuilder<T, A extends RouteArguments>
    = IPageScreen<RouteInfo<T, A>> Function();

class SimpleRouteInfo<T, A extends RouteArguments> extends RouteInfo<T, A> {
  final SimpleScreenBuilder<T, A> screen;

  const SimpleRouteInfo._({
    required RouteName name,
    required ArgumentFactory<A> argumentsFactory,
    required this.screen,
    PlatformRouteType routeType = PlatformRouteType.material,
    bool fullscreenDialog = false,
    bool isDialog = false,
  }) : super(
          name,
          argumentsFactory,
          routeType: routeType,
          fullscreenDialog: fullscreenDialog,
          isDialog: isDialog,
        );

  @override
  IPageScreen<RouteInfo<T, A>> build(BuildContext context, A arguments) {
    return screen();
  }
}

typedef SimpleArgumentScreenBuilder<T, A extends RouteArguments>
    = IPageScreen<RouteInfo<T, A>> Function({required A arguments});

class SimpleArgumentRouteInfo<T, A extends RouteArguments>
    extends RouteInfo<T, A> {
  final SimpleArgumentScreenBuilder<T, A> screen;

  const SimpleArgumentRouteInfo._({
    required RouteName name,
    required ArgumentFactory<A> argumentsFactory,
    required this.screen,
    PlatformRouteType routeType = PlatformRouteType.material,
    bool fullscreenDialog = false,
    bool isDialog = false,
  }) : super(
          name,
          argumentsFactory,
          routeType: routeType,
          fullscreenDialog: fullscreenDialog,
          isDialog: isDialog,
        );

  @override
  IPageScreen<RouteInfo<T, A>> build(BuildContext context, A arguments) {
    return screen(arguments: arguments);
  }
}

typedef ZeroArgumentScreenBuilder<T> = IPageScreen<NoArgumentsRouteInfo<T>>
    Function();

class SimpleNoArgumentRouteInfo<T> extends NoArgumentsRouteInfo<T> {
  final ZeroArgumentScreenBuilder<T> screen;

  const SimpleNoArgumentRouteInfo._({
    required RouteName name,
    required this.screen,
    PlatformRouteType routeType = PlatformRouteType.material,
    bool fullscreenDialog = false,
    bool isDialog = false,
  }) : super(
          name,
          routeType: routeType,
          fullscreenDialog: fullscreenDialog,
          isDialog: isDialog,
        );

  @override
  build(BuildContext context, [arguments]) {
    return screen();
  }
}

typedef NoArgumentScreenBuilder<T> = IPageScreen<NoArgumentsRouteInfo<T>>
    Function(BuildContext context);

class NoArgumentRouteInfoBuilder<T> extends NoArgumentsRouteInfo<T> {
  final NoArgumentScreenBuilder<T> builder;

  const NoArgumentRouteInfoBuilder._({
    required RouteName name,
    required this.builder,
    PlatformRouteType routeType = PlatformRouteType.material,
    bool fullscreenDialog = false,
    bool isDialog = false,
  }) : super(
          name,
          routeType: routeType,
          fullscreenDialog: fullscreenDialog,
          isDialog: isDialog,
        );

  @override
  build(BuildContext context, [arguments]) {
    return builder(context);
  }
}

abstract class RouteArguments {
  Map<String, dynamic> toJson();
}

abstract class ArgumentFactory<T> {
  T fromMap(Map<String, dynamic> map);
}

class RouteZeroArguments implements RouteArguments {
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

class RouteArgument<X> implements RouteArguments {
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

abstract class JsonArgument<T> implements RouteArguments, Json {}

class JsonArgumentFactory<A extends JsonArgument<A>>
    implements ArgumentFactory<A> {
  final Factory<A> creator;
  const JsonArgumentFactory(this.creator);
  @override
  A fromMap(Map<String, dynamic> map) {
    return creator(map);
  }
}

class SimpleArgument<A extends Json> implements RouteArguments {
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

class MapArgument implements RouteArguments {
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
