import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class PhotoService {
  final ImagePicker _picker = ImagePicker();

  /// Returns the selected image path or null if cancelled.
  Future<String?> pickPhoto() async {
    try {
      if (_isDesktop) {
        return _pickDesktopPhoto();
      }

      return _pickMobilePhoto();
    } catch (e) {
      debugPrint('PhotoService error: $e');
      return null;
    }
  }

  bool get _isDesktop =>
      Platform.isWindows ||
      Platform.isLinux ||
      Platform.isMacOS;

  Future<String?> _pickDesktopPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null) {
      return null;
    }

    return result.files.single.path;
  }

  Future<String?> _pickMobilePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 2000,
    );

    if (image == null) {
      return null;
    }

    return image.path;
  }  /// Returns true if the supplied photo path exists.
  Future<bool> photoExists(
    String? path,
  ) async {
    if (path == null || path.isEmpty) {
      return false;
    }

    return File(path).exists();
  }

  /// Deletes a photo from disk.
  /// Returns true if successful.
  Future<bool> deletePhoto(
    String? path,
  ) async {
    if (path == null || path.isEmpty) {
      return false;
    }

    try {
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
      }

      return true;
    } catch (e) {
      debugPrint('Delete photo error: $e');
      return false;
    }
  }
}