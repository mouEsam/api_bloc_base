import 'dart:async';

abstract class IJsonConvertor {
  FutureOr<dynamic> deserialize(String obj);
  FutureOr<String> serialize(dynamic obj);
}
