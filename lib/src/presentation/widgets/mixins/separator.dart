import 'dart:math';

import 'package:flutter/material.dart';

mixin SeparatorMixin on Widget {
  List<Widget> separateList(List<Widget> items) {
    return _seperateList(this, items);
  }
}

extension SeperationUtils on Widget {
  List<Widget> separateList(List<Widget> items) {
    return _seperateList(this, items);
  }
}

List<Widget> _seperateList(Widget seperator, List<Widget> items) {
  if (items.length <= 1) {
    return items;
  }
  final List<Widget> newItems = [];
  for (int i = 0; i < max(items.length - 1, 1); i++) {
    final child = items[i];
    newItems.add(child);
    newItems.add(seperator);
  }
  newItems.add(items.last);
  return newItems;
}