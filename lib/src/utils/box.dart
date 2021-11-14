class Box<T extends Object?> {
  final bool _mutable;
  T? _data;

  Box([this._data, this._mutable = true]);

  T get data => _data as T;

  T? get nullableData => _data;

  bool get isMutable => _mutable;

  bool get hasData => _data != null;

  set data(T? data) {
    if (_mutable) {
      _data = data;
    }
  }

  @override
  String toString() {
    return data.toString();
  }

  @override
  bool operator ==(Object other) {
    return other is Box<T> && other.nullableData == nullableData;
  }

  @override
  int get hashCode => 0;
}

T? unboxIfNotNull<T>(Box<T>? box, T? orElse) =>
    box != null ? box.nullableData : orElse;
