import 'dart:collection';

import 'package:api_bloc_base/src/presentation/bloc/worker/pagination_mixin.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

abstract class PaginationList<T> extends ListMixin<T>
    implements Paginated<PaginationList<T>> {
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

  PaginationList<S> map<S>(S f(T element));

  PageList<T> get asSinglePage;

  PaginationList<T> get item => this;
}

class PageList<T> extends PaginationList<T> {
  final List<T> _list;

  factory PageList([List<T>? list]) {
    return PageList._(list ?? []);
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

  PageList<S> map<S>(S f(T element)) {
    final list = _list.map(f).toList();
    return PageList._(list);
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
    return PageList._(_list);
  }

  @override
  get asSinglePage => this;
}

class PagesList<T> extends PaginationList<T> {
  final List<PageList<T>> _pages;

  factory PagesList([List<PageList<T>>? list]) {
    return PagesList._(list ?? []);
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

  Tuple2<PageList<T>, int> pageForIndex(int index) {
    int offset = 0;
    for (final page in _pages) {
      final _index = index - offset;
      if (_index < page.length) {
        return Tuple2(page, _index);
      } else {
        offset += page.length - 1;
      }
    }
    throw IndexError(index, this);
  }

  Tuple2<PageList<T>, int>? pageForObject(Object? object) {
    for (final page in _pages) {
      final index = page.indexOf(object);
      if (index > -1) return Tuple2(page, index);
    }
    return null;
  }

  Tuple2<PageList<T>, int>? pageWhere(bool Function(T item) predicate) {
    for (final page in _pages) {
      final index = page.indexWhere(predicate);
      if (index > -1) return Tuple2(page, index);
    }
    return null;
  }

  @override
  T operator [](int index) {
    return pageForIndex(index).apply((a, b) => a[b]);
  }

  @override
  void operator []=(int index, T value) {
    pageForIndex(index).apply((a, b) => a[b] = value);
  }

  @override
  set length(int newLength) {
    throw FlutterError("Can't resize locked list");
  }

  @override
  void insert(int index, T element) {
    pageForIndex(index).apply((a, b) => a.insert(b, element));
  }

  @override
  void insertAll(int index, Iterable<T> iterable) {
    pageForIndex(index).apply((a, b) => a.insertAll(b, iterable));
  }

  @override
  T firstWhere(bool Function(T element) test, {T Function()? orElse}) {
    final index = indexWhere(test);
    if (index > -1)
      return this[index];
    else if (orElse != null) return orElse();
    throw StateError("No element");
  }

  @override
  T lastWhere(bool Function(T element) test, {T Function()? orElse}) {
    final index = lastIndexWhere(test);
    if (index > -1)
      return this[index];
    else if (orElse != null) return orElse();
    throw StateError("No element");
  }

  @override
  int lastIndexWhere(bool Function(T element) test, [int? start]) {
    if (start == null || start >= this.length) start = this.length - 1;
    final startPage = pageForIndex(start);
    int offset = start - startPage.value2;
    {
      final index = startPage.apply((a, b) => a.lastIndexWhere(test, b));
      if (index > -1) {
        return offset + index;
      }
    }
    final startPageIndex = _pages.indexOf(startPage.value1);
    for (final page in _pages.skip(startPageIndex + 1).toList().reversed) {
      final index = page.lastIndexWhere(test);
      if (index > -1) {
        return offset + index;
      } else {
        offset += page.length - 1;
      }
    }
    return -1;
  }

  @override
  int lastIndexOf(Object? element, [int? start]) {
    if (start == null || start >= this.length) start = this.length - 1;
    final startPage = pageForIndex(start);
    int offset = start - startPage.value2;
    {
      final index = startPage.apply((a, b) => a.lastIndexOf(element, b));
      if (index > -1) {
        return offset + index;
      }
    }
    final startPageIndex = _pages.indexOf(startPage.value1);
    for (final page in _pages.skip(startPageIndex + 1).toList().reversed) {
      final index = page.lastIndexOf(element);
      if (index > -1) {
        return offset + index;
      } else {
        offset += page.length - 1;
      }
    }
    return -1;
  }

  @override
  int indexOf(Object? element, [int start = 0]) {
    final startPage = pageForIndex(start);
    int offset = start - startPage.value2;
    {
      final index = startPage.apply((a, b) => a.indexOf(element, b));
      if (index > -1) {
        return offset + index;
      }
    }
    final startPageIndex = _pages.indexOf(startPage.value1);
    for (final page in _pages.skip(startPageIndex + 1)) {
      final index = page.indexOf(element);
      if (index > -1) {
        return offset + index;
      } else {
        offset += page.length - 1;
      }
    }
    return -1;
  }

  @override
  int indexWhere(bool Function(T element) test, [int start = 0]) {
    final startPage = pageForIndex(start);
    int offset = start - startPage.value2;
    {
      final index = startPage.apply((a, b) => a.indexWhere(test, b));
      if (index > -1) {
        return offset + index;
      }
    }
    final startPageIndex = _pages.indexOf(startPage.value1);
    for (final page in _pages.skip(startPageIndex + 1)) {
      final index = page.indexWhere(test);
      if (index > -1) {
        return offset + index;
      } else {
        offset += page.length - 1;
      }
    }
    return -1;
  }

  @override
  T removeAt(int index) {
    return pageForIndex(index).apply((a, b) => a.removeAt(b));
  }

  @override
  bool remove(Object? element) {
    return pageForObject(element)?.apply((a, b) => a.remove(b)) == true;
  }

  @override
  void removeWhere(bool Function(T element) test) {
    return pageWhere(test)?.apply((a, b) => a.removeAt(b));
  }

  @override
  T removeLast() {
    for (final page in _pages.reversed) {
      if (page.isNotEmpty) {
        return page.removeLast();
      }
    }
    throw StateError("No element");
  }

  void tweak(T f(T element)) {
    for (int x = 0; x < _pages.length; x++) {
      _pages[x].tweak(f);
    }
  }

  PagesList<S> map<S>(S f(T element)) {
    final pages = _pages.map((page) {
      return page.map(f).toList();
    }).toList();
    return PagesList._(pages);
  }

  List<T> get list {
    return _pages.expand((element) => element).toList();
  }

  PagesList<T> toList({bool? growable}) {
    return PagesList._(_pages.toList());
  }

  @override
  get asSinglePage => PageList._(list);
}
