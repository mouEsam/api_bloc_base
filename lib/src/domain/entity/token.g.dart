// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserToken _$UserTokenFromJson(Map<String, dynamic> json) => UserToken(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      expiration: json['expiration'] == null
          ? null
          : DateTime.parse(json['expiration'] as String),
    );

Map<String, dynamic> _$UserTokenToJson(UserToken instance) => <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'expiration': instance.expiration?.toIso8601String(),
    };
