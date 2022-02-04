import 'dart:async';

import 'package:dio/dio.dart';

class ChainedCancelToken implements CancelToken {
  final CancelToken? first;
  CancelToken? second;

  ChainedCancelToken(this.first);

  bool get isCancellable => first != null || second != null;

  @override
  bool get isCancelled => second?.isCancelled ?? first?.isCancelled ?? false;

  @override
  void cancel([reason]) {
    if (second != null) {
      return second!.cancel(reason);
    } else if (first != null) {
      return first!.cancel(reason);
    }
  }

  @override
  get requestOptions => second?.requestOptions ?? first?.requestOptions;

  @override
  get cancelError => second?.cancelError ?? first?.cancelError;

  @override
  get whenCancel {
    return second?.whenCancel ??
        first?.whenCancel ??
        Completer<DioError>().future;
  }

  @override
  set requestOptions(_requestOptions) {
    if (second != null) {
      second!.requestOptions = _requestOptions;
    } else if (first != null) {
      first!.requestOptions = _requestOptions;
    }
  }
}
