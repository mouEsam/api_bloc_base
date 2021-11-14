import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class StadiumIndicator extends Decoration {
  final Color color;

  StadiumIndicator(this.color);

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _SolidIndicatorPainter(this, onChanged);
  }
}

class _SolidIndicatorPainter extends BoxPainter {
  final StadiumIndicator decoration;

  _SolidIndicatorPainter(this.decoration, VoidCallback? onChanged)
      : assert(decoration != null),
        super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    assert(configuration != null);
    assert(configuration.size != null);

    final Rect rect = offset & configuration.size!;
    final Radius radius = Radius.circular(rect.shortestSide / 2);
    final RRect rRect = RRect.fromRectAndRadius(rect, radius);
    final Paint paint = Paint();
    paint.color = decoration.color;
    paint.style = PaintingStyle.fill;
    paint.strokeWidth = 10.0;
    canvas.drawRRect(rRect, paint);
  }
}
