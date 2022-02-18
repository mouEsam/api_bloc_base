import 'package:api_bloc_base/src/presentation/bloc/provider/_index.dart';
import 'package:flutter/cupertino.dart';

class AppWrapper extends StatefulWidget {
  final LifecycleObserver lifecycleObserver;
  final WidgetBuilder builder;

  const AppWrapper(
      {Key? key, required this.lifecycleObserver, required this.builder})
      : super(key: key);

  @override
  _AppWrapperState createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
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
