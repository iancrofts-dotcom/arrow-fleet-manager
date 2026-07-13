import 'dart:io';

import 'package:path_provider/path_provider.dart';

class PdfExportService {
  const PdfExportService();

  Future<File> savePdf(
    List<int> pdfBytes,
    String fileName,
  ) async {
    final directory =
        await getApplicationDocumentsDirectory();

    final file = File(
      '${directory.path}/$fileName.pdf',
    );

    await file.writeAsBytes(pdfBytes);

    return file;
  }
}