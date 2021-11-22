import 'package:json_annotation/json_annotation.dart';

import 'entity.dart';

part 'token.g.dart';

@JsonSerializable()
class UserToken extends Entity {
  UserToken({
    required this.accessToken,
    this.refreshToken,
    this.expiration,
  }) : super([accessToken, refreshToken, expiration]);

  final String accessToken;
  final String? refreshToken;
  final DateTime? expiration;

  factory UserToken.fromJson(Map<String, dynamic> json) =>
      _$UserTokenFromJson(json);
  Map<String, dynamic> toJson() => _$UserTokenToJson(this);
}
