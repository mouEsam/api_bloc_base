import 'package:device_info_plus/device_info_plus.dart';
import 'package:universal_platform/universal_platform.dart';

abstract class DeviceInfo {
  static Future<DeviceInfo> initialize() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    if (UniversalPlatform.isIOS) {
      return _DeviceInfoImpl._(iosDeviceInfo: await deviceInfoPlugin.iosInfo);
    } else if (UniversalPlatform.isAndroid) {
      return _DeviceInfoImpl._(
          androidDeviceInfo: await deviceInfoPlugin.androidInfo);
    } else if (UniversalPlatform.isMacOS) {
      return _DeviceInfoImpl._(
          macOsDeviceInfo: await deviceInfoPlugin.macOsInfo);
    } else if (UniversalPlatform.isWindows) {
      return _DeviceInfoImpl._(
          windowsDeviceInfo: await deviceInfoPlugin.windowsInfo);
    } else if (UniversalPlatform.isLinux) {
      return _DeviceInfoImpl._(
          linuxDeviceInfo: await deviceInfoPlugin.linuxInfo);
    } else {
      return _DeviceInfoImpl._(
          webBrowserInfo: await deviceInfoPlugin.webBrowserInfo);
    }
  }

  String get deviceType;

  String get deviceName;
}

class _DeviceInfoImpl implements DeviceInfo {
  final IosDeviceInfo? iosDeviceInfo;
  final AndroidDeviceInfo? androidDeviceInfo;
  final LinuxDeviceInfo? linuxDeviceInfo;
  final WindowsDeviceInfo? windowsDeviceInfo;
  final MacOsDeviceInfo? macOsDeviceInfo;
  final WebBrowserInfo? webBrowserInfo;

  const _DeviceInfoImpl._(
      {this.iosDeviceInfo,
      this.androidDeviceInfo,
      this.linuxDeviceInfo,
      this.windowsDeviceInfo,
      this.macOsDeviceInfo,
      this.webBrowserInfo});

  @override
  get deviceName {
    return iosDeviceInfo?.name ??
        androidDeviceInfo?.model ??
        linuxDeviceInfo?.name ??
        windowsDeviceInfo?.computerName ??
        webBrowserInfo?.browserName.toString() ??
        macOsDeviceInfo?.computerName ??
        "device";
  }

  @override
  get deviceType {
    if (UniversalPlatform.isIOS) {
      return "ios";
    } else if (UniversalPlatform.isAndroid) {
      return "android";
    } else {
      return "other";
    }
  }
}
