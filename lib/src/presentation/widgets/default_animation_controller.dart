import 'dart:async';

import 'package:flutter/material.dart';

class DefaultAnimationController extends StatefulWidget {
  final double? value;
  final Duration? duration;
  final Duration? delay;
  final Duration? reverseDuration;
  final Duration? reverseDelay;
  final double lowerBound;
  final double upperBound;
  final AnimationBehavior animationBehavior;
  final bool autoStart;
  final bool autoReverse;
  final VoidCallback? onDone;
  final Widget Function(BuildContext, AnimationController) builder;

  const DefaultAnimationController({
    Key? key,
    required this.builder,
    this.value,
    this.delay,
    this.duration,
    this.reverseDuration,
    this.reverseDelay,
    this.onDone,
    this.lowerBound = 0.0,
    this.upperBound = 1.0,
    this.animationBehavior = AnimationBehavior.normal,
    this.autoStart = true,
    this.autoReverse = false,
  }) : super(key: key);

  @override
  _DefaultAnimationControllerState createState() =>
      _DefaultAnimationControllerState();
}

class _DefaultAnimationControllerState extends State<DefaultAnimationController>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  Timer? _timer;

  @override
  void initState() {
    _animationController = AnimationController(
        vsync: this,
        value: widget.value,
        duration: widget.duration,
        reverseDuration: widget.reverseDuration,
        lowerBound: widget.lowerBound,
        upperBound: widget.upperBound,
        animationBehavior: widget.animationBehavior);
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.autoReverse) {
          Future.delayed(widget.reverseDelay ?? Duration.zero,
              _animationController.reverse);
        } else {
          widget.onDone?.call();
        }
      }
      if (status == AnimationStatus.dismissed) {
        widget.onDone?.call();
      }
    });
    if (widget.autoStart) {
      if (widget.delay != null) {
        _timer = Timer(widget.delay!, () {
          _animationController.forward();
        });
      } else {
        _animationController.forward();
      }
    }
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _animationController);
  }
}
