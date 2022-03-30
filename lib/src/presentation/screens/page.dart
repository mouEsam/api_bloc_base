import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MaterialPageResultRoute<T> extends MaterialPageRoute<T>
    with ContentBuilder, PageRouteMixin<T> {
  MaterialPageResultRoute({
    required WidgetBuilder builder,
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

class CupertinoPageResultRoute<T> extends CupertinoPageRoute<T>
    with ContentBuilder, PageRouteMixin<T> {
  CupertinoPageResultRoute({
    required WidgetBuilder builder,
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

mixin ContentBuilder {
  Widget buildContent(BuildContext context);
}

mixin PageRouteMixin<T> on PageRoute<T>, ContentBuilder {
  T? _result;
  @override
  T? get currentResult => _result;
  void setResult(T? result) {
    _result = result;
  }

  @override
  Widget buildContent(BuildContext context) {
    return PageRouteScope(
      page: this,
      child: super.buildContent(context),
    );
  }
}

class PageRouteScope extends InheritedWidget {
  const PageRouteScope({
    Key? key,
    required this.page,
    required Widget child,
  }) : super(key: key, child: child);

  final PageRouteMixin page;

  @override
  bool updateShouldNotify(oldWidget) {
    return false;
  }

  static PageRouteMixin<T> of<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PageRouteScope>()!.page
        as PageRouteMixin<T>;
  }
}
