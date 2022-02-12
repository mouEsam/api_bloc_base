import 'package:json_annotation/json_annotation.dart';

part 'base_errors.g.dart';

@JsonSerializable()
class BaseErrors {
  const BaseErrors({this.message, this.errors = const {}});

  final String? message;
  final Map<String, List<String>> errors;

  BaseErrors withMessage(String? message) {
    return BaseErrors(message: message ?? this.message, errors: errors);
  }

  factory BaseErrors.fromJson(Map<String, dynamic> json) =>
      _$BaseErrorsFromJson(json);
  Map<String, dynamic> toJson() => _$BaseErrorsToJson(this);
}
