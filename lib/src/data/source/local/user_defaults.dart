import 'dart:convert';

import 'package:api_bloc_base/src/domain/entity/base_profile.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserDefaults {
  final storage = const FlutterSecureStorage();
  final BaseProfile Function(Map<String, dynamic> json) profileFactory;
  const UserDefaults(this.profileFactory);

  Future<void> setUserToken(String? userToken) {
    if (userToken == null) {
      return storage.delete(key: _USER_TOKEN);
    } else {
      return storage.write(key: _USER_TOKEN, value: userToken);
    }
  }

  Future<String?> get userToken {
    return storage.read(key: _USER_TOKEN);
  }

  Future<void> setSignedAccount(BaseProfile? profile) {
    print('saving account $profile');
    final json = jsonEncode(profile?.toJson());
    if (json.isEmpty) {
      return storage.delete(key: _SIGNED_ACCOUNT);
    } else {
      return storage.write(key: _SIGNED_ACCOUNT, value: json);
    }
  }

  Future<BaseProfile?> get signedAccount {
    return storage.read(key: _SIGNED_ACCOUNT).then((value) {
      if (value == null) {
        return null;
      } else {
        final json = jsonDecode(value);
        if (json != null) {
          final profile = profileFactory(json);
          return profile;
        } else {
          return null;
        }
      }
    }, onError: (e, s) {
      print(e);
      print(s);
      return null;
    });
  }

  Future<void> setFirstTime(DateTime dataTime) {
    return storage.write(key: _FIRST_TIME, value: dataTime.toIso8601String());
  }

  Future<DateTime?> get firstTime {
    return storage.read(key: _FIRST_TIME).then((value) {
      if (value == null) {
        return null;
      } else {
        return DateTime.tryParse(value)!;
      }
    }, onError: (e, s) {
      print(e);
      print(s);
      return null;
    });
  }
}

extension on UserDefaults {
  static const _USER_TOKEN = 'user_token';
  static const _FIRST_TIME = 'first_time';
  static const _SIGNED_ACCOUNT = 'signed_in_account';
}
