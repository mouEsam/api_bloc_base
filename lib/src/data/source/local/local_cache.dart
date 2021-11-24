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
    Database db = await _createDatabase();
    return LocalCache._(db);
  }

  static Future<Database> _createDatabase() async {
    if (UniversalPlatform.isWeb) {
      return databaseFactoryWeb.openDatabase('cache/$dbPath');
    } else {
      final directory = await getApplicationDocumentsDirectory();
      return databaseFactoryIo.openDatabase('${directory.path}/cache/$dbPath');
    }
  }
}
