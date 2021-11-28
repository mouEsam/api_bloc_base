import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

abstract class Entity extends Equatable {
  final List<Object?> _props;

  const Entity([this._props = const []]);

  @JsonKey(ignore: true)
  get stringify => true;

  @override
  List<Object?> get props => _props;
}
