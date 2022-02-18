import 'package:api_bloc_base/src/presentation/bloc/provider/_index.dart';
import 'package:flutter/cupertino.dart';

class MyApp extends StatefulWidget {
  final LifecycleObserver lifecycleObserver;
  final WidgetBuilder builder;

  const MyApp(
      {Key? key, required this.lifecycleObserver, required this.builder})
      : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(widget.lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(widget.lifecycleObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}
