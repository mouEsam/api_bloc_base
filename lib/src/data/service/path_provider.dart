import 'dart:io';

import 'package:path_provider/path_provider.dart' as Path;
import 'package:universal_platform/universal_platform.dart';

abstract class PathProvider {
  static bool _initialized = false;
  static late final PathProvider instance;

  static PathProvider initialize() {
    if (_initialized) return instance;
    if (UniversalPlatform.isWeb) {
      instance = _WebPathProviderImpl();
    } else {
      instance = _StandalonePathProviderImpl();
    }
    _initialized = true;
    return instance;
  }

  /// Path to the temporary directory on the device that is not backed up and is
  /// suitable for storing caches of downloaded files.
  Future<Directory> getTemporaryDirectory() => throw UnimplementedError();

  /// Path to a directory where the application may place application support
  /// files.
  Future<Directory> getApplicationSupportDirectory() =>
      throw UnimplementedError();

  /// Path to the directory where application can store files that are persistent,
  /// backed up, and not visible to the user, such as sqlite.db.
  Future<Directory> getLibraryDirectory() => throw UnimplementedError();

  /// Path to a directory where the application may place data that is
  /// user-generated, or that cannot otherwise be recreated by your application.
  Future<Directory> getApplicationDocumentsDirectory() =>
      throw UnimplementedError();

  /// Path to a directory where the application may access top level storage.
  /// The current operating system should be determined before issuing this
  /// function call, as this functionality is only available on Android.
  Future<Directory?> getExternalStorageDirectory() =>
      throw UnimplementedError();

  /// Paths to directories where application specific external cache data can be
  /// stored. These paths typically reside on external storage like separate
  /// partitions or SD cards. Phones may have multiple storage directories
  /// available.
  Future<List<Directory>?> getExternalCacheDirectories() =>
      throw UnimplementedError();

  /// Paths to directories where application specific data can be stored.
  /// These paths typically reside on external storage like separate partitions
  /// or SD cards. Phones may have multiple storage directories available.
  Future<List<Directory>?> getExternalStorageDirectories(
    /// Optional parameter. See [StorageDirectory] for more informations on
    /// how this type translates to Android storage directories.
    Path.StorageDirectory? type,
  ) =>
      throw UnimplementedError();

  /// Path to the directory where downloaded files can be stored.
  /// This is typically only relevant on desktop operating systems.
  Future<Directory?> getDownloadsDirectory() => throw UnimplementedError();
}

class _StandalonePathProviderImpl extends PathProvider {
  @override
  getApplicationDocumentsDirectory() => Path.getApplicationDocumentsDirectory();

  @override
  getApplicationSupportDirectory() => Path.getApplicationSupportDirectory();

  @override
  getDownloadsDirectory() => Path.getDownloadsDirectory();

  @override
  getExternalCacheDirectories() => Path.getExternalCacheDirectories();

  @override
  getExternalStorageDirectory() => Path.getExternalStorageDirectory();

  @override
  getExternalStorageDirectories(Path.StorageDirectory? type) =>
      Path.getExternalStorageDirectories(type: type);

  @override
  getLibraryDirectory() => Path.getLibraryDirectory();

  @override
  getTemporaryDirectory() => Path.getTemporaryDirectory();
}

class _WebPathProviderImpl extends PathProvider {}
