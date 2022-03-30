import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// [FlutterTransformer] is especially for flutter, by which the json decoding
/// will be in background with [compute] function.

/// FlutterTransformer
class FlutterTransformer extends DefaultTransformer {
  FlutterTransformer() : super(jsonDecodeCallback: _parseJson);
}

// Must be top-level function
_parseAndDecode(String response) {
  return jsonDecode(response);
}

_parseJson(String text) {
  return compute(_parseAndDecode, text);
}
