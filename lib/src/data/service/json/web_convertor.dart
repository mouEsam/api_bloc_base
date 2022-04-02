import 'dart:convert';

import 'package:api_bloc_base/src/data/service/json/convertor.dart';

class JsonWebConvertor implements IJsonConvertor {
  const JsonWebConvertor();

  dynamic deserialize(String obj) {
    return jsonDecode(obj);
  }

  String serialize(dynamic obj) {
    return jsonEncode(obj);
  }
}
