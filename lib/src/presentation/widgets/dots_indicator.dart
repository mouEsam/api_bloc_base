import 'dart:math';

import 'package:flutter/material.dart';

class DotsIndicator extends AnimatedWidget {
  const DotsIndicator({
    required Listenable listenable,
    required this.itemCount,
    this.onPageSelected,
    this.page,
    this.expandH = false,
    this.color,
    this.selectedColor,
  }) : super(listenable: listenable);

  final double? page;
  final int itemCount;
  final ValueChanged<int>? onPageSelected;
  final Color? color;
  final Color? selectedColor;
  final bool expandH;
  static const double _kDotSize = 8.0;
  static const double _kMaxZoom = 2.0;
  static const double _kDotSpacing = 12.0;

  Widget _buildDot(int index) {
    final page = this.page ?? 0.0;
    final selected = index == page.round();
    final color = this.color ?? Colors.white.withAlpha(200);
    final selectedColor = this.selectedColor ?? Colors.white;
    double selectness = Curves.easeOut.transform(
      max(
        0.0,
        1.0 - (page - index).abs(),
      ),
    );
    double zoom = 1.0 + (_kMaxZoom - 1.0) * selectness;
    return Container(
      //width: _kDotSpacing,
      margin: const EdgeInsets.symmetric(horizontal: 2.5),
      child: Center(
        child: Material(
          color: Color.lerp(color, selectedColor, selectness),
          type: expandH && selected ? MaterialType.card : MaterialType.circle,
          child: Container(
            //duration: const Duration(milliseconds: 100),
            width: (expandH && selected ? zoom * 1.2 : zoom) * _kDotSize,
            height: expandH ? _kDotSize : _kDotSize * zoom,
            child: InkWell(
              onTap: () => onPageSelected?.call(index),
            ),
          ),
        ),
      ),
    );
  }

  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(itemCount, _buildDot),
    );
  }
}
