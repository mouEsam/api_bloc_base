import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class LoadMoreDetector extends StatelessWidget {
  final Object? state;
  final EdgeInsets padding;
  final void Function() loadMore;

  const LoadMoreDetector(
      {Key? key,
      required this.state,
      required this.loadMore,
      this.padding = const EdgeInsets.all(10)})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey(state),
      onVisibilityChanged: (VisibilityInfo info) {
        if (info.visibleFraction >= 0.2) {
          loadMore();
        }
      },
      child: Padding(
        padding: padding,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
