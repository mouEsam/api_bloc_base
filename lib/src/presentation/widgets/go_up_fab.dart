import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GoUpFab extends StatelessWidget {
  const GoUpFab({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size / 2;
    return AnimatedBuilder(
      animation: scrollController,
      builder: (BuildContext context, Widget? child) {
        final show = scrollController.positions.last.pixels > size.height;
        return AnimatedOpacity(
          opacity: show ? 1 : 0,
          duration: Duration(milliseconds: 300),
          child: IgnorePointer(
            child: child,
            ignoring: !show,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: FloatingActionButton(
          heroTag: null,
          onPressed: () {
            final multiplier = scrollController.offset / size.height;
            scrollController.animateTo(0,
                duration: Duration(milliseconds: (200 * multiplier).round()),
                curve: Curves.easeInCubic);
          },
          child: Icon(CupertinoIcons.chevron_up),
        ),
      ),
    );
  }
}
