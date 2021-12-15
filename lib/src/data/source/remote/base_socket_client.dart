import 'dart:io';
import 'dart:ui';

import 'package:api_bloc_base/src/data/model/_index.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketOptions {
  bool? forceNew;
  bool? forceNewConnection;
  bool? multiplex;
  bool? autoConnect;
  num? reconnectionAttempts;
  int? reconnectionDelay;
  int? reconnectionDelayMax;
  num? randomizationFactor;
  int? timeout;
  bool? reconnectionEnabled;
  String? path;
  List<String>? transports;
  Map<String, dynamic>? extraHeaders;
  Map<String, dynamic>? queryParameters;

  SocketOptions();

  SocketOptions.defaultOptions() {
    forceNew = false;
    forceNewConnection = false;
    multiplex = false;
    autoConnect = false;
    reconnectionEnabled = false;
    transports = ['websocket']; // for Flutter or Dart VM
    extraHeaders = {};
  }
}

class BaseSocketClient {
  final Uri baseUrl;
  final SocketOptions defaultOptions;

  const BaseSocketClient._(this.baseUrl, this.defaultOptions);

  factory BaseSocketClient(String baseUrl, [SocketOptions? options]) {
    options ??= SocketOptions.defaultOptions();
    return BaseSocketClient._(Uri.parse(baseUrl), options);
  }

  static Map<String, dynamic> _buildOptions(Iterable<SocketOptions> options) {
    var builder = IO.OptionBuilder();
    for (final option in options) {
      builder = _createOptions(builder, option);
    }
    return builder.build();
  }

  static IO.OptionBuilder _createOptions(
      IO.OptionBuilder optionsBuilder, SocketOptions socketOptions) {
    final reconnectionAttempts = socketOptions.reconnectionAttempts;
    if (reconnectionAttempts != null) {
      optionsBuilder.setReconnectionAttempts(reconnectionAttempts);
    }
    final reconnectionDelay = socketOptions.reconnectionDelay;
    if (reconnectionDelay != null) {
      optionsBuilder.setReconnectionDelay(reconnectionDelay);
    }
    final reconnectionDelayMax = socketOptions.reconnectionDelayMax;
    if (reconnectionDelayMax != null) {
      optionsBuilder.setReconnectionDelayMax(reconnectionDelayMax);
    }
    final randomizationFactor = socketOptions.randomizationFactor;
    if (randomizationFactor != null) {
      optionsBuilder.setRandomizationFactor(randomizationFactor);
    }
    final timeout = socketOptions.timeout;
    if (timeout != null) {
      optionsBuilder.setTimeout(timeout);
    }
    final forceNew = socketOptions.forceNew;
    if (forceNew != null) {
      if (forceNew == true) {
        optionsBuilder.enableForceNew();
      } else {
        optionsBuilder.disableForceNew();
      }
    }
    final forceNewConnection = socketOptions.forceNewConnection;
    if (forceNewConnection != null) {
      if (forceNewConnection) {
        optionsBuilder.enableForceNewConnection();
      } else {
        optionsBuilder.disableForceNewConnection();
      }
    }
    final multiplex = socketOptions.multiplex;
    if (multiplex != null) {
      if (multiplex) {
        optionsBuilder.enableMultiplex();
      } else {
        optionsBuilder.disableMultiplex();
      }
    }
    final autoConnect = socketOptions.autoConnect;
    if (autoConnect != null) {
      if (autoConnect) {
        optionsBuilder.enableAutoConnect();
      } else {
        optionsBuilder.disableAutoConnect();
      }
    }
    final reconnectionEnabled = socketOptions.reconnectionEnabled;
    if (reconnectionEnabled != null) {
      if (reconnectionEnabled) {
        optionsBuilder.enableReconnection();
      } else {
        optionsBuilder.disableReconnection();
      }
    }
    final queryParameters = socketOptions.queryParameters;
    if (queryParameters != null) {
      optionsBuilder.setQuery(queryParameters);
    }
    final path = socketOptions.path;
    if (path != null) {
      optionsBuilder.setPath(path);
    }
    final transports = socketOptions.transports;
    if (transports != null) {
      optionsBuilder.setTransports(transports);
    }
    final extraHeaders = socketOptions.extraHeaders;
    if (extraHeaders != null) {
      optionsBuilder.setExtraHeaders(extraHeaders);
    }
    return optionsBuilder;
  }

  request(
    String path, {
    String? authorizationToken,
    Params? params,
    String? subDomain,
    bool pathIsUrl = false,
    dynamic acceptedLanguage,
    SocketOptions? options,
    QueryParams? queryParams,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) {
    queryParameters ??= <String, dynamic>{};
    if (queryParams != null) {
      queryParameters.addAll(queryParams.getQueryParams());
    }
    queryParameters.removeWhere((k, v) => v == null);
    queryParameters.forEach((key, value) {
      if (value is List) {
        value.removeWhere((element) => element == null);
      }
    });
    headers ??= <String, dynamic>{};
    if (acceptedLanguage is Locale) {
      headers[HttpHeaders.acceptLanguageHeader] = acceptedLanguage.languageCode;
    } else if (acceptedLanguage != null) {
      headers[HttpHeaders.acceptLanguageHeader] = acceptedLanguage.toString();
    }
    if (authorizationToken != null) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $authorizationToken';
    }

    var newBaseUrl = pathIsUrl ? Uri.parse(path) : baseUrl;
    if (subDomain != null) {
      var splitHost = newBaseUrl.host.split('.');
      if (splitHost.length >= 3) {
        splitHost[0] = subDomain;
      } else {
        splitHost.insert(0, subDomain);
      }
      final newHost = splitHost.join('.');
      newBaseUrl = newBaseUrl.replace(host: newHost);
    }
    var newPath = pathIsUrl ? newBaseUrl.path : path;
    newBaseUrl = newBaseUrl.replace(path: "");

    final internalOptions = SocketOptions();
    internalOptions.queryParameters = queryParameters;
    internalOptions.extraHeaders = headers;
    internalOptions.path = newPath;

    var opts = _buildOptions(
        [defaultOptions, options, internalOptions].whereType<SocketOptions>());

    final socket = IO.io(newBaseUrl.toString(), opts);
    return socket;
  }
}
