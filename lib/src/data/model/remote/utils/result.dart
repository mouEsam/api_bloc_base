import 'dart:async';

import 'package:dio/dio.dart';

import 'cancel_token.dart';

class Result<T> {
  final CancelToken? cancelToken;
  final Future<T> resultFuture;
  final Stream<double>? progress;

  const Result({this.cancelToken, required this.resultFuture, this.progress});

  Result<S> chain<S>(Result<S> Function(T value) secondFactory) {
    return ChainedResult<T, S>(this, secondFactory);
  }

  Result<S> next<S>(FutureOr<S> Function(T value) secondFactory) {
    return chain<S>((value) {
      final future = secondFactory(value);
      return Result(resultFuture: Future.value(future));
    });
  }
}

class CompletableResult<T> extends Result<T> {
  final Completer<T> _completer;

  CompletableResult(this._completer,
      {CancelToken? cancelToken, Stream<double>? progress})
      : super(
            resultFuture: _completer.future,
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
    _completer.future.whenComplete(() => _progress.close());
    if (first.progress != null) {
      _progress.addStream(first.progress!);
    }
    first.resultFuture.then((value) {
      final _second = secondFactory(value);
      _completer.complete(_second.resultFuture);
      second = _second;
      cancelToken.second = _second.cancelToken;
      if (_second.progress != null) {
        _progress.addStream(_second.progress!);
      }
    }, onError: (e, s) {
      _completer.completeError(e, s);
    });
  }
}

extension FutureResult<T> on Future<T> {
  Future<T?> get maybe {
    return this.catchError((e, s) {}).then<T?>((value) => value);
  }

  Result<S> result<S>(FutureOr<S> Function(T value) nextProcess) {
    return Result(resultFuture: this).next(nextProcess);
  }

  Result<S> next<S>(Result<S> Function(T value) nextProcess) {
    return Result(resultFuture: this).chain(nextProcess);
  }

  Result<S> chain<S>(Result<S> nextProcess) {
    return Result(resultFuture: this).chain((_) => nextProcess);
  }
}
