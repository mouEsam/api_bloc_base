import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

abstract class PaginationList<T> extends ListMixin<T> {
  PaginationList._();

  factory PaginationList.single([List<T>? page]) {
    return PageList._(page ?? []);
  }

  factory PaginationList.multi([List<PageList<T>>? pages]) {
    return PagesList._(pages ?? []);
  }

  @override
  PaginationList<T> toList({bool? growable});

  void tweak(T f(T element));
}

class PageList<T> extends PaginationList<T> {
  final List<T> _list;

  factory PageList([List<T>? list]) {
    return PageList(list ?? []);
  }

  PageList._(this._list) : super._();

  void addPage(PageList<T> page) {
    addAll(page._list);
  }

  void addPages(List<PageList<T>> pages) {
    pages.forEach(addPage);
  }

  void tweak(T f(T element)) {
    for (int i = 0; i < _list.length; i++) {
      _list[i] = f(_list[i]);
    }
  }

  @override
  int get length => _list.length;

  @override
  T operator [](int index) {
    return _list[index];
  }

  @override
  void operator []=(int index, T value) {
    _list[index] = value;
  }

  @override
  set length(int newLength) {
    _list.length = newLength;
  }

  @override
  @protected
  PageList<T> toList({bool? growable}) {
    return this;
  }
}

class PagesList<T> extends PaginationList<T> {
  final List<PageList<T>> _pages;

  factory PagesList([List<PageList<T>>? list]) {
    return PagesList(list ?? []);
  }

  PagesList._(this._pages) : super._();

  factory PagesList.empty() {
    return PagesList._([]);
  }

  void addPage(PaginationList<T> page) {
    if (page is PageList<T>) {
      _pages.add(page);
    } else if (page is PagesList<T>) {
      _pages.addAll(page._pages);
    }
  }

  void addPages(List<PaginationList<T>> pages) {
    if (pages is List<PageList<T>>) {
      _pages.addAll(pages);
    } else if (pages is List<PagesList<T>>) {
      pages.forEach(addPage);
    }
  }

  @override
  void add(T element) {
    if (_pages.isEmpty) _pages.add(PageList._([]));
    _pages.last.add(element);
  }

  @override
  void addAll(Iterable<T> iterable) {
    if (_pages.isEmpty) _pages.add(PageList._([]));
    _pages.last.addAll(iterable);
  }

  @override
  int get length => _pages.fold(
      0, (previousValue, element) => previousValue + element.length);

  @override
  T operator [](int index) {
    int offset = 0;
    for (final page in _pages) {
      final _index = index - offset - 1;
      if (index < page.length) {
        return page[_index];
      } else {
        offset += page.length;
      }
    }
    throw IndexError(index, this);
  }

  @override
  void operator []=(int index, T value) {
    this[index] = value;
  }

  @override
  set length(int newLength) {}

  void tweak(T f(T element)) {
    for (int x = 0; x < _pages.length; x++) {
      _pages[x].tweak(f);
    }
  }

  List<T> get list {
    return _pages.expand((element) => element).toList();
  }

  PagesList<T> toList({bool? growable}) {
    return PagesList._(_pages.toList());
  }
}
