import 'package:flutter/material.dart';

class WidgetAnimator extends StatefulWidget {
  final bool enabled;
  final Widget child;

  const WidgetAnimator({Key? key, required this.child, this.enabled = true})
      : super(key: key);

  @override
  _WidgetAnimatorState createState() => _WidgetAnimatorState();
}

class _WidgetAnimatorState extends State<WidgetAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 350),
        value: widget.enabled ? 1 : 0,
        lowerBound: 0,
        upperBound: 1);
    super.initState();
  }

  @override
  void didUpdateWidget(WidgetAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizeTransition(
      sizeFactor:
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
      child: FadeTransition(
        opacity:
            CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
        child: widget.child,
      ),
    );
  }
}
