import 'package:flutter/material.dart';

class Disposer extends StatefulWidget {
  final Widget child;
  final List<ChangeNotifier> disposables;

  const Disposer({Key? key, required this.child, required this.disposables})
      : super(key: key);

  @override
  _DisposerState createState() => _DisposerState();
}

class _DisposerState extends State<Disposer> {
  @override
  void dispose() {
    widget.disposables.map((e) => e.dispose()).toList();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
