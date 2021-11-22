import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

abstract class Entity extends Equatable {
  final List<Object?> _props;

  const Entity([this._props = const []]);

  @JsonKey(ignore: true)
  get stringify => true;

  @JsonKey(ignore: true)
  List<String>? get serverSuccessMessages => null;

  @override
  List<Object?> get props => _props;
}
