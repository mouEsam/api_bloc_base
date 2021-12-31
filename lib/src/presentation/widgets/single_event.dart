import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SingleEventWidget extends StatefulWidget {
  final String eventKey;
  final FutureOr<bool> Function(BuildContext context) handler;
  final Widget? child;
  final Widget Function(
      BuildContext context, bool handled, VoidCallback setHandled,
      [Widget? child]) builder;

  const SingleEventWidget({
    Key? key,
    required this.eventKey,
    required this.handler,
    this.child,
    required this.builder,
  }) : super(key: key);

  @override
  _SingleEventState createState() => _SingleEventState();
}

class _SingleEventState extends State<SingleEventWidget> {
  final _storage = const FlutterSecureStorage();
  bool _isHandled = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      _isHandled = await _handled;
      if (!_isHandled) {
        if (await widget.handler(context)) {
          setHandled();
        }
      } else {
        update();
      }
    });
  }

  Future<void> setHandled() async {
    _isHandled = true;
    await _setHandled(_isHandled);
    update();
  }

  void update() {
    setState(() {});
  }

  Future<void> _setHandled(bool handled) {
    if (!handled) {
      return _storage.delete(key: widget.eventKey);
    } else {
      return _storage.write(
          key: widget.eventKey,
          value: DateTime.now().toUtc().toIso8601String());
    }
  }

  Future<bool> get _handled {
    return _storage.containsKey(key: widget.eventKey);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _isHandled, setHandled, widget.child);
  }
}
