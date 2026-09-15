import 'dart:typed_data';

import '../report_export_result.dart';

Future<ReportExportResult> saveBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) =>
    throw UnsupportedError('Report export is not supported on this platform.');
