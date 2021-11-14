import 'package:api_bloc_base/src/presentation/bloc/base/visibility_mixin.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VisibilityWrapper extends StatelessWidget {
  final Widget child;
  final VisibilityMixin visibilityDetector;
  final void Function() loadMore;

  const VisibilityWrapper(
      {Key? key,
      required this.child,
      required this.visibilityDetector,
      required this.loadMore})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ObjectKey(visibilityDetector),
      onVisibilityChanged: (VisibilityInfo info) {
        if (info.visibleFraction > 0.0) {
          visibilityDetector.setVisible(false);
        } else {
          visibilityDetector.setVisible(true);
        }
      },
      child: child,
    );
  }
}
