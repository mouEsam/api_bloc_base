import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ValueListener<T> extends StatelessWidget {
  final ValueListenable<T> value;
  final Widget? child;
  final ValueWidgetBuilder<T> builder;
  final bool isSliver;

  const ValueListener({
    Key? key,
    required this.value,
    required this.builder,
    this.child,
  })  : isSliver = false,
        super(key: key);

  const ValueListener.sliver({
    Key? key,
    required this.value,
    required this.builder,
    this.child,
  })  : isSliver = true,
        super(key: key);

  const ValueListener.custom({
    Key? key,
    required this.value,
    required this.builder,
    required this.isSliver,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: value,
      builder: builder,
      child: child,
    );
  }
}
