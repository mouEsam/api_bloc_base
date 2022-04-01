import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

import 'page.dart';
import 'screen.dart';

abstract class RouteName {
  const RouteName._();

  const factory RouteName.autoReplace({
    Iterable<Type>? types,
    Map<Pattern, String> replacements,
  }) = AutoName._;

  const factory RouteName.auto({
    Iterable<Type>? types,
    bool? withoutRoute,
    bool? withoutScreen,
    bool? withoutDialog,
    bool? ignoreCase,
  }) = AutoNameWithOptions._;

  const factory RouteName.trim({
    Iterable<Type>? types,
    bool? withoutRoute,
    bool? withoutScreen,
    bool? withoutDialog,
    bool? ignoreCase,
  }) = AutoNameWithOptions._trim;

  const factory RouteName.withoutRoute({
    Iterable<Type>? types,
    bool? ignoreCase,
  }) = AutoNameWithOptions._withoutRoute;

  const factory RouteName.withoutScreen({
    Iterable<Type>? types,
    bool? ignoreCase,
  }) = AutoNameWithOptions._withoutScreen;

  const factory RouteName.withoutDialog({
    Iterable<Type>? types,
    bool? ignoreCase,
  }) = AutoNameWithOptions._withoutDialog;

  const factory RouteName(String name) = ManualName.new;

  String getName(RouteInfo route);
}

class AutoName extends RouteName {
  final Iterable<Type>? types;
  final Map<Pattern, String> replacements;
  const AutoName._({this.types, this.replacements = const {}}) : super._();

  @override
  String getName(RouteInfo route) {
    final types = this.types ?? [route.runtimeType];
    return types.map((type) {
      final routeTypeName = type.toString();
      var routeName = routeTypeName;
      replacements.forEach((key, value) {
        routeName = routeName.replaceAll(key, value);
      });
      return routeName;
    }).join('/');
  }
}

class AutoNameWithOptions extends RouteName {
  final Iterable<Type>? types;
  final bool? withoutRoute;
  final bool? withoutScreen;
  final bool? withoutDialog;
  final bool? ignoreCase;

  const AutoNameWithOptions._({
    this.types,
    this.withoutRoute,
    this.withoutScreen,
    this.withoutDialog,
    this.ignoreCase,
  }) : super._();

  const AutoNameWithOptions._withoutRoute({
    this.types,
    this.ignoreCase,
  })  : withoutRoute = true,
        withoutScreen = null,
        withoutDialog = null,
        super._();

  const AutoNameWithOptions._withoutScreen({
    this.types,
    this.ignoreCase,
  })  : withoutScreen = true,
        withoutRoute = null,
        withoutDialog = null,
        super._();

  const AutoNameWithOptions._withoutDialog({
    this.types,
    this.ignoreCase,
  })  : withoutDialog = true,
        withoutScreen = null,
        withoutRoute = null,
        super._();

  const AutoNameWithOptions._trim({
    this.types,
    this.ignoreCase,
    this.withoutRoute = true,
    this.withoutDialog = true,
    this.withoutScreen = true,
  }) : super._();

  @override
  String getName(RouteInfo route) {
    final types = this.types ?? [route.runtimeType];
    return types.map((type) {
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
    }).join('/');
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
  final bool rootNavigator;
  final bool fullscreenDialog;
  final bool? barrierDismissible;
  final Color? barrierColor;
  final String? barrierLabel;

  const RouteParameters({
    required this.uri,
    required this.settings,
    required this.routeType,
    required this.rootNavigator,
    required this.fullscreenDialog,
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
  final RouteBuilder<T, A>? routeBuilder;
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
    this.routeBuilder,
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
  }) = RouteInfoBuilder<T, A>._;

  const factory RouteInfo.simple({
    required RouteName name,
    required ArgumentFactory<A> argumentsFactory,
    required SimpleScreenBuilder<T, A> screen,
    PlatformRouteType routeType,
    bool fullscreenDialog,
    bool isDialog,
  }) = SimpleRouteInfo<T, A>._;

  const factory RouteInfo.argument({
    required RouteName name,
    required ArgumentFactory<A> argumentsFactory,
    required SimpleArgumentScreenBuilder<T, A> screen,
    PlatformRouteType routeType,
    bool fullscreenDialog,
    bool isDialog,
  }) = SimpleArgumentRouteInfo<T, A>._;

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

  RouteBuilder<T, A> getRouteBuilder() {
    return routeBuilder ?? RouteBuilder<T, A>();
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

    return getRouteBuilder().buildPageRoute(
      RouteParameters(
        uri: uri,
        settings: settings,
        rootNavigator: false,
        routeType: routeType ?? this.routeType,
        fullscreenDialog: fullscreenDialog ?? this.fullscreenDialog,
      ),
      routeArgs,
      this,
      (context, arguments) {
        return build(context, arguments);
      },
    );
  }

  Route<T> buildDialog(
    BuildContext context, {
    required Uri uri,
    required RouteSettings settings,
    bool rootNavigator = true,
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

    return getRouteBuilder().buildDialogRoute(
      context,
      RouteParameters(
        uri: uri,
        settings: settings,
        routeType: routeType ?? this.routeType,
        fullscreenDialog: false,
        barrierDismissible: barrierDismissible ?? this.barrierDismissible,
        rootNavigator: rootNavigator,
        barrierColor: barrierColor ?? this.barrierColor,
        barrierLabel: barrierLabel ?? this.barrierLabel,
      ),
      routeArgs,
      this,
      (context, arguments) {
        return build(context, arguments);
      },
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

  void pop(
    BuildContext context, {
    required T result,
    bool rootNavigator = false,
  }) {
    return Navigator.of(context, rootNavigator: rootNavigator).pop(result);
  }

  void popSaved(
    BuildContext context, {
    T? result,
    bool rootNavigator = false,
  }) {
    result = stateOf(context).currentResult;
    return pop(context, result: result as T, rootNavigator: rootNavigator);
  }

  Future<bool> maybePop(
    BuildContext context, {
    required T result,
    bool rootNavigator = false,
  }) {
    return Navigator.of(context, rootNavigator: rootNavigator).maybePop(result);
  }

  Future<bool> maybePopSaved(
    BuildContext context, {
    T? result,
    bool rootNavigator = false,
  }) {
    result = stateOf(context).currentResult;
    return maybePop(context, result: result as T, rootNavigator: rootNavigator);
  }

  Future<T?> pushClearTop<R>(
    BuildContext context, {
    required A arguments,
    bool rootNavigator = false,
    R? result,
  }) async {
    if (result != null) {
      await Navigator.of(context, rootNavigator: rootNavigator)
          .maybePop(result);
    }
    return Navigator.of(context, rootNavigator: rootNavigator)
        .pushNamedAndRemoveUntil<T>(
      createUri(arguments).toString(),
      (route) => false,
      arguments: arguments,
    );
  }

  Future<T?> push(
    BuildContext context, {
    required A arguments,
    bool? rootNavigator,
  }) {
    if (isDialog) {
      rootNavigator ??= true;
      return Navigator.of(context, rootNavigator: rootNavigator).push<T>(
        buildDialog(
          context,
          uri: createUri(arguments),
          settings: RouteSettings(
            arguments: arguments,
          ),
          rootNavigator: rootNavigator,
        ),
      );
    } else {
      rootNavigator ??= false;
      return Navigator.of(context, rootNavigator: rootNavigator).pushNamed<T>(
        createUri(arguments).toString(),
        arguments: arguments,
      );
    }
  }

  Future<T?> replace<R>(
    BuildContext context, {
    required A arguments,
    bool? rootNavigator,
    R? result,
    bool? popAndPush,
  }) {
    if (isDialog) {
      return _replaceDialog<R>(
        context,
        arguments: arguments,
        result: result,
        rootNavigator: rootNavigator ?? true,
      );
    } else {
      return _replacePage<R>(
        context,
        arguments: arguments,
        result: result,
        popAndPush: popAndPush,
        rootNavigator: rootNavigator ?? false,
      );
    }
  }

  Future<T?> _replacePage<R>(
    BuildContext context, {
    required A arguments,
    required bool rootNavigator,
    R? result,
    bool? popAndPush,
  }) {
    final action = () {
      if (popAndPush == true) {
        return Navigator.of(context, rootNavigator: rootNavigator)
            .popAndPushNamed;
      } else {
        return Navigator.of(context, rootNavigator: rootNavigator)
            .pushReplacementNamed;
      }
    }();
    return action<T, R>(
      createUri(arguments).toString(),
      arguments: arguments,
      result: result,
    );
  }

  Future<T?> _replaceDialog<R>(
    BuildContext context, {
    required A arguments,
    required bool rootNavigator,
    R? result,
  }) {
    return Navigator.of(context, rootNavigator: rootNavigator)
        .pushReplacement<T, R>(
      buildDialog(
        context,
        uri: createUri(arguments),
        settings: RouteSettings(
          arguments: arguments,
        ),
        rootNavigator: rootNavigator,
      ),
      result: result,
    );
  }

  Future<T?> refresh(
    BuildContext context, {
    bool? rootNavigator,
    T? result,
    bool? popAndPush,
  }) {
    final arguments = this(context).arguments;
    return replace<T>(
      context,
      arguments: arguments,
      result: result,
      popAndPush: popAndPush,
      rootNavigator: rootNavigator,
    );
  }

  void setResult(BuildContext context, T? result) {
    return stateOf(context).setResult(result);
  }

  bool hasResult(BuildContext context) {
    return stateOf(context).currentResult is T;
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

typedef RouteScreenBuilder<T, A extends RouteArguments>
    = IPageScreen<RouteInfo<T, A>> Function(
  BuildContext context,
  A arguments,
);

abstract class RouteBuilder<T, A extends RouteArguments> {
  const factory RouteBuilder() = DefaultRouteBuilder<T, A>.new;

  Route<T> buildPageRoute(
    RouteParameters params,
    A arguments,
    RouteInfo<T, A> route,
    RouteScreenBuilder<T, A> builder,
  );

  Route<T> buildDialogRoute(
    BuildContext context,
    RouteParameters params,
    A arguments,
    RouteInfo<T, A> route,
    RouteScreenBuilder<T, A> builder,
  );
}

class DefaultRouteBuilder<T, A extends RouteArguments>
    implements RouteBuilder<T, A> {
  const DefaultRouteBuilder();

  @override
  Route<T> buildPageRoute(
    RouteParameters params,
    A arguments,
    RouteInfo<T, A> route,
    RouteScreenBuilder<T, A> builder,
  ) {
    final routeBuilder = () {
      if (params.routeType == PlatformRouteType.cupertino ||
          (params.routeType == PlatformRouteType.adaptive &&
              (UniversalPlatform.isIOS || UniversalPlatform.isMacOS))) {
        return CupertinoPageResultRoute<T, A, RouteInfo<T, A>>.new;
      } else {
        return MaterialPageResultRoute<T, A, RouteInfo<T, A>>.new;
      }
    }();

    return routeBuilder(
      builder: (context) {
        return builder(context, arguments);
      },
      route: route,
      uri: params.uri,
      arguments: arguments,
      settings: params.settings,
      fullscreenDialog: params.fullscreenDialog,
    );
  }

  @override
  Route<T> buildDialogRoute(
    BuildContext context,
    RouteParameters params,
    A arguments,
    RouteInfo<T, A> route,
    RouteScreenBuilder<T, A> builder,
  ) {
    if (params.routeType == PlatformRouteType.cupertino ||
        (params.routeType == PlatformRouteType.adaptive &&
            (UniversalPlatform.isIOS || UniversalPlatform.isMacOS))) {
      return buildCupertinoDialogRoute(
          context, params, arguments, route, builder);
    } else {
      return buildMaterialDialogRoute(
          context, params, arguments, route, builder);
    }
  }

  Route<T> buildMaterialDialogRoute(
    BuildContext context,
    RouteParameters params,
    A arguments,
    RouteInfo<T, A> route,
    RouteScreenBuilder<T, A> builder,
  ) {
    final CapturedThemes themes = InheritedTheme.capture(
      from: context,
      to: Navigator.of(
        context,
        rootNavigator: params.rootNavigator,
      ).context,
    );
    return MaterialDialogResultRoute<T, A, RouteInfo<T, A>>(
      context: context,
      builder: (context) {
        return builder(context, arguments);
      },
      route: route,
      uri: params.uri,
      themes: themes,
      arguments: arguments,
      settings: params.settings,
      barrierColor: params.barrierColor ?? Colors.black54,
      barrierLabel: params.barrierLabel,
      barrierDismissible: params.barrierDismissible ?? true,
    );
  }

  Route<T> buildCupertinoDialogRoute(
    BuildContext context,
    RouteParameters params,
    A arguments,
    RouteInfo<T, A> route,
    RouteScreenBuilder<T, A> builder,
  ) {
    return CupertinoDialogResultRoute<T, A, RouteInfo<T, A>>(
      context: context,
      builder: (context) {
        return builder(context, arguments);
      },
      route: route,
      uri: params.uri,
      arguments: arguments,
      settings: params.settings,
      barrierColor: params.barrierColor,
      barrierLabel: params.barrierLabel,
      barrierDismissible: params.barrierDismissible ?? true,
    );
  }
}

mixin NoResultRouteMixin on RouteInfo<void, RouteZeroArguments> {
  @override
  void pop(
    BuildContext context, {
    void result,
    bool rootNavigator = false,
  }) {
    return super.pop(context, result: null, rootNavigator: rootNavigator);
  }

  @override
  Future<bool> maybePop(
    BuildContext context, {
    required void result,
    bool rootNavigator = false,
  }) {
    return super.maybePop(context, result: null, rootNavigator: rootNavigator);
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
  }) = NoArgumentRouteInfoBuilder<T>._;

  const factory NoArgumentsRouteInfo.simple({
    required RouteName name,
    required ZeroArgumentScreenBuilder<T> screen,
    PlatformRouteType routeType,
    bool fullscreenDialog,
    bool isDialog,
  }) = SimpleNoArgumentRouteInfo<T>._;

  @override
  @protected
  IPageScreen<NoArgumentsRouteInfo<T>> build(
    BuildContext context, [
    RouteZeroArguments arguments = RouteInfo.noArgs,
  ]);

  @override
  Future<T?> pushClearTop<R>(
    BuildContext context, {
    RouteZeroArguments arguments = RouteInfo.noArgs,
    bool rootNavigator = false,
    R? result,
  }) {
    return super.pushClearTop(
      context,
      arguments: arguments,
      result: result,
      rootNavigator: rootNavigator,
    );
  }

  @override
  Future<T?> push(
    BuildContext context, {
    RouteZeroArguments arguments = RouteInfo.noArgs,
    bool? rootNavigator,
  }) {
    return super.push(
      context,
      arguments: arguments,
      rootNavigator: rootNavigator,
    );
  }

  @override
  Future<T?> replace<R>(
    BuildContext context, {
    RouteZeroArguments arguments = RouteInfo.noArgs,
    bool? rootNavigator,
    R? result,
    bool? popAndPush,
  }) {
    return super.replace(
      context,
      arguments: arguments,
      result: result,
      rootNavigator: rootNavigator,
    );
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
  build(BuildContext context, [arguments = RouteInfo.noArgs]) {
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
  build(BuildContext context, [arguments = RouteInfo.noArgs]) {
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

typedef FromJsonFactory<J extends Json> = J Function(Map<String, dynamic> json);

abstract class JsonArgument<T> implements RouteArguments, Json {}

class JsonArgumentFactory<A extends JsonArgument<A>>
    implements ArgumentFactory<A> {
  final FromJsonFactory<A> creator;
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
