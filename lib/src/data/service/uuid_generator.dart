import 'dart:math';

import 'package:uuid/uuid.dart';

class UuidGenerator {
  final _uuid = const Uuid();

  String timeBasedUuid() => _uuid.v4();

  String randomUuid() => _uuid.v1();

  String forNamespace(String namespace) =>
      _uuid.v5(Uuid.NAMESPACE_URL, namespace);

  String generateRandomString([int len = 8]) {
    var r = Random.secure();
    const _chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(len, (index) => _chars[r.nextInt(_chars.length)])
        .join();
  }

  int generateRandomNumber([int len = 8]) {
    var r = Random.secure();
    return r.nextInt(pow(10, len - 1) - 1 as int);
  }

  int generateTimeBasedNumberV2() {
    int i = DateTime.now().millisecondsSinceEpoch;
    var r = Random.secure();
    var randomInt = r.nextInt(pow(2, 32) as int);
    randomInt += i;
    return randomInt;
  }

  int generateTimeBasedNumber() {
    int i = DateTime.now().millisecondsSinceEpoch;
    var r = Random.secure();
    var randomInt = r.nextInt(pow(2, 32) as int);
    var randomPart = randomInt.toString().length;
    final sup = pow(10, randomPart - 1);
    i = i ~/ sup;
    i *= sup as int;
    i += randomInt;
    return i;
  }
}
