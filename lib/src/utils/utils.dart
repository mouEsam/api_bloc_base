extension NullableObjectUtils<T> on T? {
  S? let<S>(S? Function(T it) mapper) {
    return this == null ? null : mapper(this!);
  }
}

extension ObjectUtils<T> on T {
  S map<S>(S Function(T it) mapper) {
    return mapper(this);
  }
}
