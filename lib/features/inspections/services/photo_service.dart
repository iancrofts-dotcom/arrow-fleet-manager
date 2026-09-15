import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class InspectionPhotoSelection {
  const InspectionPhotoSelection({
    required this.fileName,
    required this.bytes,
    required this.contentType,
  });

  final String fileName;
  final Uint8List bytes;
  final String contentType;
}

class PhotoService {
  final ImagePicker _picker = ImagePicker();

  Future<InspectionPhotoSelection?> pickPhoto() async {
    try {
      if (kIsWeb || _isDesktop) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
        if (result == null) return null;
        final file = result.files.single;
        final bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) return null;
        return InspectionPhotoSelection(
          fileName: file.name,
          bytes: bytes,
          contentType: _contentType(file.name),
        );
      }

      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (image == null) return null;
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) return null;
      return InspectionPhotoSelection(
        fileName: image.name.isEmpty ? 'inspection-photo.jpg' : image.name,
        bytes: bytes,
        contentType: _contentType(image.name),
      );
    } catch (e) {
      debugPrint('PhotoService error: $e');
      return null;
    }
  }

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;

  String _contentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
