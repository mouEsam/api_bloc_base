import 'package:api_bloc_base/src/presentation/bloc/base/visibility_mixin.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VisibilityWrapper extends StatelessWidget {
  final Widget child;
  final VisibilityMixin? visibilityDetector;
  final ValueChanged<double>? onVisibilityChanged;

  const VisibilityWrapper(
      {required Key key,
      required this.child,
      this.visibilityDetector,
      this.onVisibilityChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: key!,
      onVisibilityChanged: (VisibilityInfo info) {
        onVisibilityChanged?.call(info.visibleFraction);
        if (info.visibleFraction > 0.0) {
          visibilityDetector?.setVisible(true);
        } else {
          visibilityDetector?.setVisible(false);
        }
      },
      child: child,
    );
  }
}
