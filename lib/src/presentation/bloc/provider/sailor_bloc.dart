import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/base_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:listenable_stream/listenable_stream.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uni_links/uni_links.dart' as uni_links;
import 'package:universal_platform/universal_platform.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

abstract class Sailor {
  GlobalKey<NavigatorState> get navKey;
  Future<T?> pushDestructively<T>(String routeName);
  Future<T?> push<T>(String routeName);
  Future<void> goHome();
  Future<void> popNum(int routes);
}

abstract class SailorBloc extends BaseCubit<NavigationState> implements Sailor {
  static const _localHost = "localhost";

  final GlobalKey<NavigatorState> navKey = GlobalKey();
  String get mainHost;
  String get localHost => _localHost;
  String get internalInitialRoute;
  String get internalMainRoute;

  late final StreamSubscription _sub;
  late final StreamSubscription<Uri?> _linkSub;

  String? _loadedLink;

  bool _mainPageLoaded = false;
  bool get mainPageLoaded => _mainPageLoaded;

  String get initialRoute => _loadedLink ?? internalInitialRoute;

  @override
  get stream => super.stream.distinct();

  List<Stream> get eventsStreams;

  Map<Type, FutureOr<void> Function(BuildContext, NavigationState)> get actions;

  SailorBloc(NavigationState initialState) : super(initialState) {
    final combinedStream =
        CombineLatestStream(eventsStreams, generateNavigationState);
    final initialized = ensureInitialized()
        .asStream()
        .doOnData(onKeyInitialized)
        .asBroadcastStream(onCancel: (c) => c.cancel());
    _sub = initialized
        .switchMap((value) => combinedStream)
        .asyncMap((event) async => event)
        .whereType<NavigationState>()
        .listen(emit);
    initialized.switchMap((value) => this.stream).listen(_handleState);

    late final Stream<Uri?> linkStream;
    if (UniversalPlatform.isWeb) {
      linkStream = uni_links.getInitialUri().asStream();
    } else {
      linkStream = uni_links.uriLinkStream;
    }
    _linkSub = linkStream.listen((link) {
      if (link != null) {
        handleUri(link);
      }
    }, onError: (err, s) {
      print("Received initial link error");
      print(err);
      print(s);
    });
  }

  Future<void> onKeyInitialized(GlobalKey<NavigatorState> navKey) async {}

  Future<GlobalKey<NavigatorState>> ensureInitialized() async {
    if (navKey.currentContext != null) {
      return navKey;
    }
    await Future.doWhile(() async {
      await Future.delayed(Duration(microseconds: 1000), () {});
      return navKey.currentContext == null;
    });
    return navKey;
  }

  void _handleState(NavigationState event) {
    print("NavigationState ${event.runtimeType}");
    final type = event.runtimeType;
    final operation = actions[type];
    if (operation != null) {
      operation(navKey.currentContext!, event);
    } else if (event is MainPageState) {
      handleMainPage(navKey.currentContext!, event);
    }
  }

  @mustCallSuper
  Future<void> handleMainPage(BuildContext context, MainPageState state) async {
    setMainPageLoaded();
    state.push(this, internalMainRoute);
    if (_loadedLink != null) {
      print(_loadedLink);
      push(_loadedLink!);
      _loadedLink = null;
    }
  }

  void setMainPageLoaded() {
    _mainPageLoaded = true;
  }

  Future<void> handleUri(Uri link) async {
    if (link.host.isNotEmpty &&
        link.host != mainHost &&
        link.host != localHost &&
        await launcher.canLaunch(link.toString())) {
      debugPrint("Launching $link");
      await launcher.launch(link.toString());
      return;
    }
    link = Uri(
        path: link.path,
        query: link.query,
        queryParameters: link.queryParameters,
        fragment: link.fragment);
    final loadedLink = link
        .toString()
        .trim()
        .replaceFirst("/?#", '')
        .replaceFirst("/?%23", '');
    print("Received initial link $loadedLink");
    if (loadedLink.isNotEmpty) {
      _loadedLink = loadedLink;
    }
    if (_loadedLink != null && mainPageLoaded) {
      pushDestructively(_loadedLink!);
      _loadedLink = null;
    }
  }

  FutureOr<NavigationState>? generateNavigationState(List events);

  Future<T?> pushDestructively<T>(String routeName) async {
    final key = await ensureInitialized();
    final result = await key.currentState!
        .pushNamedAndRemoveUntil(routeName, (r) => false);
    return result as T?;
  }

  Future<T?> push<T>(String routeName) async {
    final key = await ensureInitialized();
    final result = await key.currentState!.pushNamed(routeName);
    return result as T?;
  }

  Future<void> goHome() async {
    final key = await ensureInitialized();
    key.currentState!.popUntil((route) => route.isFirst);
  }

  Future<void> popNum(int routes) async {
    int count = 0;
    final key = await ensureInitialized();
    key.currentState!.popUntil((route) => count++ == routes);
  }

  @override
  Future<void> close() {
    _sub.cancel();
    _linkSub.cancel();
    return super.close();
  }
}

abstract class NavigationState extends Equatable implements Type {
  const NavigationState();

  void push(Sailor sailor, String routeName) {
    sailor.pushDestructively(routeName);
  }

  @override
  get stringify => true;
  @override
  get props => [];
}

class MainPageState extends NavigationState {}

enum _NavEventType { Add, Remove }

class _NavEvent {
  final _NavEventType type;
  final Route route;

  const _NavEvent(this.type, this.route);
}

mixin CompassMixin on Sailor implements NavigatorObserver {
  @override
  get navigator => navKey.currentState;

  final _currentRoute = ValueNotifier<Route?>(null);
  final _currentEvent = ValueNotifier<_NavEvent?>(null);

  Route? get currentRoute => _currentRoute.value;

  FutureOr<Route> awaitRoute(bool Function(Route route) predicate) {
    return _currentRoute
        .toValueStream(replayValue: true)
        .whereType<Route>()
        .firstWhere(predicate);
  }

  FutureOr<Route> awaitAdded(bool Function(Route route) predicate) {
    return _awaitEvent(predicate, _NavEventType.Add);
  }

  FutureOr<Route> awaitRemoved(bool Function(Route route) predicate) {
    return _awaitEvent(predicate, _NavEventType.Remove);
  }

  FutureOr<Route> _awaitEvent(
      bool Function(Route route) predicate, _NavEventType type) {
    return _currentEvent
        .toValueStream(replayValue: true)
        .whereType<_NavEvent>()
        .where((event) => event.type == type)
        .map((event) => event.route)
        .firstWhere(predicate);
  }

  @override
  @mustCallSuper
  void didPop(Route route, Route? previousRoute) {
    _currentRoute.value = previousRoute;
    _currentEvent.value = _NavEvent(_NavEventType.Remove, route);
    didChange(previousRoute, route);
  }

  @override
  @mustCallSuper
  void didPush(Route route, Route? previousRoute) {
    _currentRoute.value = route;
    _currentEvent.value = _NavEvent(_NavEventType.Add, route);
    didChange(previousRoute, route);
  }

  @override
  @mustCallSuper
  void didRemove(Route route, Route? previousRoute) {
    _currentRoute.value = previousRoute;
    _currentEvent.value = _NavEvent(_NavEventType.Remove, route);
    didChange(previousRoute, route);
  }

  @override
  @mustCallSuper
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _currentRoute.value = newRoute;
    if (oldRoute != null) {
      _currentEvent.value = _NavEvent(_NavEventType.Remove, oldRoute);
    }
    if (newRoute != null) {
      _currentEvent.value = _NavEvent(_NavEventType.Add, newRoute);
    }
    didChange(oldRoute, newRoute);
  }

  void didChange(Route? from, Route? to) {}

  @override
  void didStartUserGesture(Route route, Route? previousRoute) {}

  @override
  void didStopUserGesture() {}
}
