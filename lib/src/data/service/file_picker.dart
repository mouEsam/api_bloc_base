import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class MediaPicker {
  Future<String?> _pickFileFromDevice() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'bmp', 'jpeg', 'svg'],
    );
    return (result != null && result.count > 0)
        ? result.files.first.path
        : null;
  }

  Future<String?> _snapPhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
    );
    return photo?.path;
  }

  Future<String?> restoreLostData() async {
    final picker = ImagePicker();
    final photo = await picker.retrieveLostData();
    return photo.file?.path;
  }

  Future<File?> pickPhoto(bool camera) async {
    String? path;
    if (camera) {
      path = await _snapPhoto();
    } else {
      path = await _pickFileFromDevice();
    }
    if (path != null) {
      return File(path);
    }
    return null;
  }
}
