import 'package:flutter/material.dart';

class PageSlider extends StatelessWidget {
  final Widget? child;
  final double? width;

  const PageSlider({Key? key, this.child, this.width}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 400),
      layoutBuilder: (child, children) {
        return Container(
          width: width ?? MediaQuery.of(context).size.width,
          child: Stack(
            children: <Widget>[
              ...children,
              if (child != null) child,
            ],
            alignment: Alignment.topCenter,
            fit: StackFit.loose,
          ),
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        var begin = Offset(1.0, 0.0);
        var end = Offset.zero;
        var beginOpacity = 0.0;
        var endOpacity = 1.0;
        var curve = Curves.ease;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var opacityTween = Tween(begin: beginOpacity, end: endOpacity)
            .chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        var opacityAnimation = animation.drive(opacityTween);
        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(opacity: opacityAnimation, child: child),
        );
      },
      child: Container(key: child?.key, width: double.infinity, child: child),
    );
  }
}
