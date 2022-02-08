import 'package:api_bloc_base/src/domain/entity/token.dart';
import 'package:json_annotation/json_annotation.dart';

import 'entity.dart';

abstract class BaseProfile<T extends BaseProfile<T>> extends Entity {
  const BaseProfile({
    required this.userToken,
    required this.active,
  });

  final UserToken userToken;
  final bool active;

  @JsonKey(ignore: true)
  dynamic get id;

  @JsonKey(ignore: true)
  String get accessToken => userToken.accessToken;

  T updateToken(UserToken newToken);

  @override
  get props => [userToken, active];

  Map<String, dynamic> toJson();
}
