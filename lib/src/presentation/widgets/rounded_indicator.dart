import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class RoundedIndicator extends Decoration {
  final Color color;
  final double borderRadius;

  RoundedIndicator(this.color, this.borderRadius);

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _SolidIndicatorPainter(this, onChanged);
  }
}

class _SolidIndicatorPainter extends BoxPainter {
  final RoundedIndicator decoration;

  _SolidIndicatorPainter(this.decoration, VoidCallback? onChanged)
      : assert(decoration != null),
        super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    assert(configuration != null);
    assert(configuration.size != null);

    final Rect rect = offset & configuration.size!;
    final Paint paint = Paint();
    final borderRadius = BorderRadius.circular(decoration.borderRadius);
    paint.color = decoration.color;
    paint.style = PaintingStyle.fill;
    paint.strokeWidth = 10.0;
    canvas.drawRRect(borderRadius.toRRect(rect), paint);
  }
}
