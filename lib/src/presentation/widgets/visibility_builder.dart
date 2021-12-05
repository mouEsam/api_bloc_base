import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:flutter/material.dart';

class VisibilityBuilder extends StatefulWidget {
  final Widget? child;
  final Widget Function(
      BuildContext context, double visibleFraction, Widget? child) builder;

  const VisibilityBuilder({required Key key, required this.builder, this.child})
      : super(key: key);

  @override
  State<VisibilityBuilder> createState() => _VisibilityBuilderState();
}

class _VisibilityBuilderState extends State<VisibilityBuilder> {
  double _visibleFraction = 0.0;

  @override
  Widget build(BuildContext context) {
    return VisibilityWrapper(
      key: widget.key!,
      onVisibilityChanged: (visibleFraction) {
        setState(() {
          this._visibleFraction = visibleFraction;
        });
      },
      child: widget.builder(context, _visibleFraction, widget.child),
    );
  }
}
