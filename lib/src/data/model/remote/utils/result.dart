import 'dart:async';

import 'package:api_bloc_base/src/domain/entity/_index.dart';
import 'package:dio/dio.dart';

import 'cancel_token.dart';

class Result<T> {
  final CancelToken? cancelToken;
  final FutureOr<T> value;
  final Stream<double>? progress;

  const Result({this.cancelToken, required this.value, this.progress});

  Result<S> chain<S>(Result<S> Function(T value) secondFactory) {
    return ChainedResult<T, S>(this, secondFactory);
  }

  Result<S> next<S>(FutureOr<S> Function(T value) secondFactory) {
    return chain<S>((value) {
      final future = secondFactory(value);
      return Result(value: Future.value(future));
    });
  }

  Result<T> sideEffect(FutureOr<void> Function(T value) func) {
    return this.next((value) async {
      await func(value);
      return value;
    });
  }
}

class CompletableResult<T> extends Result<T> {
  final Completer<T> _completer;

  CompletableResult(this._completer,
      {CancelToken? cancelToken, Stream<double>? progress})
      : super(
            value: _completer.future,
            cancelToken: cancelToken,
            progress: progress);

  bool get isCompleted => _completer.isCompleted;
}

class ChainedResult<S, T> extends CompletableResult<T> {
  final ChainedCancelToken cancelToken;
  final StreamController<double> _progress;
  final Result<S> first;
  Result<T>? second;

  @override
  get progress => _progress.stream;

  ChainedResult(this.first, Result<T> Function(S) secondFactory)
      : cancelToken = ChainedCancelToken(first.cancelToken),
        _progress = StreamController(),
        super(Completer()) {
    _completer.future.whenComplete(() {
      if (!_progress.isClosed) {
        _progress.close();
      }
    });
    if (first.progress != null) {
      if (!_progress.isClosed) {
        _progress.addStream(first.progress!, cancelOnError: true);
      }
    }
    Future.value(first.value).then((value) {
      final _second = secondFactory(value);
      _completer.complete(_second.value);
      second = _second;
      cancelToken.second = _second.cancelToken;
      if (_second.progress != null) {
        if (!_progress.isClosed) {
          _progress.addStream(_second.progress!, cancelOnError: true);
        }
      }
    }, onError: (e, s) {
      _completer.completeError(e, s);
    });
  }
}

extension FutureResult<T> on FutureOr<T> {
  Future<T> get future => Future.value(this);

  T? get maybeValue => this is T ? (this as T) : null;

  FutureOr<T?> get maybe {
    final value = maybeValue;
    if (value != null) {
      return value;
    }
    return future.catchError((e, s) {}).then<T?>((value) => value);
  }

  Result<T> get asResult => Result(value: this);

  Result<ResponseEntity> get asResponseResult => Result(
      value: this
          .future
          .then<ResponseEntity>((value) => const Success())
          .onError((error, stackTrace) => const Failure()));

  Result<S> result<S>(FutureOr<S> Function(T value) nextProcess) {
    return Result(value: this).next(nextProcess);
  }

  Result<S> next<S>(Result<S> Function(T value) nextProcess) {
    return Result(value: this).chain(nextProcess);
  }

  Result<S> chain<S>(Result<S> nextProcess) {
    return Result(value: this).chain((_) => nextProcess);
  }
}
