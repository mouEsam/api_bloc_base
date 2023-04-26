import 'package:permission_handler/permission_handler.dart';
import 'package:universal_platform/universal_platform.dart';

abstract class PermissionHandler {
  static bool _initialized = false;
  static late final PermissionHandler instance;

  factory PermissionHandler.initialize() {
    if (_initialized) return instance;
    if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) {
      instance = _MobilePermissionHandlerImpl();
    } else {
      instance = _WebPermissionHandlerImpl();
    }
    _initialized = true;
    return instance;
  }

  Future<bool> requestStorage();

  Future<bool> requestNotifications();
}

class _MobilePermissionHandlerImpl implements PermissionHandler {
  @override
  Future<bool> requestStorage() async {
    return _requestPerm(Permission.storage);
  }

  @override
  Future<bool> requestNotifications() async {
    return _requestPerm(Permission.notification);
  }

  Future<bool> _requestPerm(Permission perm) async {
    var status = await perm.status;
    if (!status.isGranted) {
      status = await perm.request();
    }
    return status.isGranted;
  }
}

class _WebPermissionHandlerImpl implements PermissionHandler {
  @override
  Future<bool> requestStorage() async {
    return true;
  }

  @override
  Future<bool> requestNotifications() async {
    return true;
  }
}
