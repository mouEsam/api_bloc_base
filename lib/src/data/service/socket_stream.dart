import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

typedef void EventHandler<T>(SocketStream<T> socket, dynamic data);

class Event {
  final String name;

  const Event(this.name);
}

class SocketStream<O> {
  final IO.Socket _socket;
  final O Function(dynamic data) mapper;
  final _socketResponse = StreamController<O>.broadcast();

  SocketStream(this._socket, this.mapper) {
    _socket.on('event', (data) => _socketResponse.sink.add(mapper(data)));
  }

  Stream<O> get getResponse => _socketResponse.stream.shareValue();

  void connect({
    EventHandler<O>? onConnect,
    EventHandler<O>? onDisconnect,
  }) {
    _socket.connect();
    _socket.onConnect((data) {
      _log('connected');
      onConnect?.call(this, data);
    });
    _socket.onDisconnect((data) {
      _log('disconnected');
      onDisconnect?.call(this, data);
    });
  }

  void disconnect({
    EventHandler<O>? onDisconnect,
  }) {
    _socket.disconnect();
    _socket.onDisconnect((data) {
      _log('disconnected');
      onDisconnect?.call(this, data);
    });
  }

  void reconnect({
    EventHandler<O>? onConnect,
    EventHandler<O>? onDisconnect,
  }) {
    _socket.io
      ..disconnect()
      ..connect();
    _socket.onConnect((data) {
      _log('connected');
      onConnect?.call(this, data);
    });
    _socket.onDisconnect((data) {
      _log('disconnected');
      onDisconnect?.call(this, data);
    });
  }

  void emit(Event event, [data]) {
    _socket.emit(event.name, data);
  }

  void emitBinary(Event event, [data]) {
    _socket.emitWithBinary(event.name, data);
  }

  void setHeader(String headerName, String? value) {
    final Map headers = _socket.io.options['extraHeaders'] as Map;
    if (value == null) {
      headers.remove(headerName);
    } else {
      headers[headerName] = value;
    }
  }

  void setQueryParameter(String parameter, String? value) {
    final Map queryParameter = _socket.io.options['query'] as Map;
    if (value == null) {
      queryParameter.remove(parameter);
    } else {
      queryParameter[parameter] = value;
    }
  }

  void _log(String message) {
    print(
        '${this.runtimeType}: ${DateTime.now().toIso8601String()}:: $message');
  }

  void dispose() {
    _socket.dispose();
    _socketResponse.close();
  }
}
