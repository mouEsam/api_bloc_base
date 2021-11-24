import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:universal_platform/universal_platform.dart';

class LocalCache {
  static const String dbPath = 'sample.db';

  final Database db;

  const LocalCache._(this.db);

  static Future<LocalCache> create() async {
    DatabaseFactory dbFactory =
        UniversalPlatform.isWeb ? databaseFactoryWeb : databaseFactoryIo;
    final directory = await getApplicationDocumentsDirectory();
    Database db =
        await dbFactory.openDatabase('${directory.path}/cache/$dbPath');
    return LocalCache._(db);
  }
}
