import 'dart:async';

import 'package:api_bloc_base/src/data/service/json/convertor.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

class JsonTransformer extends DefaultTransformer {
  final IJsonConvertor _convertor;
  JsonTransformer(this._convertor)
      : super(jsonDecodeCallback: _convertor.deserialize);

  @override
  Future<String> transformRequest(RequestOptions options) async {
    var data = options.data ?? '';
    if (data is! String) {
      if (_isJsonMime(options.contentType)) {
        return _convertor.serialize(options.data);
      } else if (data is Map) {
        options.contentType =
            options.contentType ?? Headers.formUrlEncodedContentType;
        return Transformer.urlEncodeMap(data);
      }
    }
    return data.toString();
  }

  bool _isJsonMime(String? contentType) {
    if (contentType == null) return false;
    return MediaType.parse(contentType).mimeType ==
        Headers.jsonMimeType.mimeType;
  }
}
