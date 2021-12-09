import 'dart:math';

import 'package:flutter/material.dart';

mixin SeparatorMixin on Widget {
  List<Widget> separateList(Iterable<Widget> items) {
    return _seperateList<Widget>(this, items.toList());
  }
}

extension SeperationUtils on Widget {
  List<W> separateList<W extends Widget>(Iterable<W> items) {
    return _seperateList<W>(this as W, items.toList());
  }
}

List<W> _seperateList<W extends Widget>(W seperator, List<W> items) {
  if (items.length <= 1) {
    return items;
  }
  final List<W> newItems = [];
  for (int i = 0; i < max(items.length - 1, 1); i++) {
    final child = items[i];
    newItems.add(child);
    newItems.add(seperator);
  }
  newItems.add(items.last);
  return newItems;
}