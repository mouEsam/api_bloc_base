import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

abstract class Entity extends Equatable {
  const Entity();

  @JsonKey(ignore: true)
  get stringify => true;

  @JsonKey(ignore: true)
  List<String>? get serverSuccessMessages => null;
}
