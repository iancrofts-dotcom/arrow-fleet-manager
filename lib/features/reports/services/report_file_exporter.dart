import 'dart:typed_data';

import 'export/report_file_exporter_stub.dart'
    if (dart.library.io) 'export/report_file_exporter_io.dart'
    if (dart.library.js_interop) 'export/report_file_exporter_web.dart'
    as platform;
import 'report_export_result.dart';

class ReportFileExporter {
  const ReportFileExporter();

  Future<ReportExportResult> savePdf(Uint8List bytes, String fileName) =>
      platform.saveBytes(
        bytes: bytes,
        fileName: _withExtension(fileName, '.pdf'),
        mimeType: 'application/pdf',
      );

  Future<ReportExportResult> saveCsv(Uint8List bytes, String fileName) =>
      platform.saveBytes(
        bytes: bytes,
        fileName: _withExtension(fileName, '.csv'),
        mimeType: 'text/csv;charset=utf-8',
      );

  String _withExtension(String fileName, String extension) =>
      fileName.toLowerCase().endsWith(extension)
      ? fileName
      : '$fileName$extension';
}
