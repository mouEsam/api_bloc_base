import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;

class JsonConvertor {
  static const _maxInt = 2 << 30;

  late final StreamController _rps;
  final Completer<Isolate> _isolate = Completer();
  final Completer<SendPort> _sp = Completer();
  final ReceivePort _rp = ReceivePort();
  final math.Random _rg = math.Random.secure();

  JsonConvertor() {
    _isolate.complete(
      () async {
        final isolate = await Isolate.spawn(_jsonWorker, _rp.sendPort);
        _rps = StreamController.broadcast();
        _rps.addStream(_rp);
        final sendPort = await _rps.stream.first as SendPort;
        _sp.complete(sendPort);
        return isolate;
      }(),
    );
  }

  Future<void> dispose() async {
    if (_isolate.isCompleted) {
      await _isolate.future.then((value) => value.kill());
      _rp.close();
      await _rps.close();
    }
  }

  static Future<void> _jsonWorker(SendPort sendPort) async {
    final ReceivePort rp = ReceivePort();
    sendPort.send(rp.sendPort);

    await for (final message in rp) {
      if (message is Map<String, dynamic>) {
        for (final entry in message.entries) {
          final key = entry.key;
          final value = entry.value;
          if (value is String) {
            final obj = jsonDecode(value);
            sendPort.send({key: obj});
          } else {
            final json = jsonEncode(value);
            sendPort.send({key: json});
          }
        }
      }
    }

    Isolate.exit();
  }

  Future<T> _get<T>(Stream steam, String key) {
    return steam
        .where((event) {
          return event is Map<String, dynamic> && event[key] != null;
        })
        .cast<Map<String, dynamic>>()
        .map((value) => value[key] as T)
        .first;
  }

  Future<R> _send<R>(dynamic obj) {
    return _sp.future.then(
      (sendPort) {
        final key = _rg.nextInt(_maxInt).toString();
        final message = {key: obj};
        sendPort.send(message);
        return _get<R>(_rps.stream, key);
      },
    );
  }

  Future<dynamic> deserialize(String obj) {
    return _send(obj);
  }

  Future<String> serialize(dynamic obj) {
    return _send(obj);
  }
}
