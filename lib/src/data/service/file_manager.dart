import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:flutter/cupertino.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as webHtml;
import 'package:universal_platform/universal_platform.dart';

import 'path_provider.dart';
import 'permission_handler.dart';

typedef XFile = File;

abstract class FileManager {
  static bool _initialized = false;
  static late final FileManager instance;

  final FileSystem fileSystem;

  const FileManager(this.fileSystem);

  static FileManager initialize(
      PermissionHandler permissionHandler, PathProvider pathProvider) {
    if (_initialized) return instance;
    if (UniversalPlatform.isWeb) {
      instance = _WebFileManagerImpl(MemoryFileSystem());
    } else {
      instance = _StandaloneFileManagerImpl._(
          permissionHandler, pathProvider, const LocalFileSystem());
    }
    _initialized = true;
    return instance;
  }

  XFile getFile(String path) => fileSystem.file(path);

  Future<XFile> getDocumentFile(String fileName);

  Future<XFile> saveDocument(
      Uint8List encoded, String type, String fileWithExt);

  Future<void> shareFile(XFile path, String mimeType, String subject);
}

class _StandaloneFileManagerImpl extends FileManager {
  final PermissionHandler permissionHandler;
  final PathProvider pathProvider;

  const _StandaloneFileManagerImpl._(this.permissionHandler, this.pathProvider,
      LocalFileSystem localFileSystem)
      : super(localFileSystem);

  @override
  Future<XFile> saveDocument(
      Uint8List encoded, String type, String fileWithExt) async {
    final documentsPath = await pathProvider.getApplicationDocumentsDirectory();
    return saveFile(false, encoded, documentsPath.path, fileWithExt);
  }

  Future<XFile> saveFile(bool dangerous, Uint8List encoded, String path,
      String fileWithExt) async {
    final file = getFile("$path/$fileWithExt");
    if (!dangerous || await permissionHandler.requestStorage()) {
      await file.create(recursive: true);
      await file.writeAsBytes(encoded);
      return file;
    }
    throw FlutterError('An authorised operation');
  }

  @override
  Future<XFile> getDocumentFile(String fileName) async {
    final documentsPath = await pathProvider.getApplicationDocumentsDirectory();
    return getFile('${documentsPath.path}/$fileName');
  }

  @override
  Future<void> shareFile(XFile path, String type, String subject) {
    return Share.shareFiles([
      path.path
    ], mimeTypes: [
      type,
    ], subject: subject);
  }
}

class _WebFileManagerImpl extends FileManager {
  const _WebFileManagerImpl(MemoryFileSystem fileSystem) : super(fileSystem);

  @override
  Future<XFile> saveDocument(
      Uint8List encoded, String type, String fileWithExt) async {
    return saveFile(encoded, type, 'Documents', fileWithExt);
  }

  Future<XFile> saveFile(
      Uint8List encoded, String type, String path, String fileWithExt) async {
    final file = getFile("$path/$fileWithExt");
    await file.create(recursive: true);
    await file.writeAsBytes(encoded);
    return file;
  }

  Future<void> downloadFile(
      Uint8List encoded, String type, String fileWithExt) async {
    var blob = webHtml.Blob(encoded, type, 'native');

    var anchorElement = webHtml.AnchorElement(
      href: webHtml.Url.createObjectUrlFromBlob(blob).toString(),
    )..setAttribute("download", fileWithExt);
    return anchorElement.click();
  }

  @override
  Future<XFile> getDocumentFile(String fileName) async {
    return getFile('Documents/$fileName');
  }

  @override
  Future<void> shareFile(XFile path, String type, String subject) async {
    await downloadFile(await path.readAsBytes(), type, path.basename);
  }
}
