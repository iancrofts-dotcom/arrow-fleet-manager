import 'dart:io';

import 'package:share_plus/share_plus.dart';

class PdfShareService {
  const PdfShareService();

  Future<void> sharePdf(File file) async {
    await Share.shareXFiles(
      [
        XFile(file.path),
      ],
      text: 'Fleet Report',
      subject: 'Arrow Fleet Manager Report',
    );
  }
}