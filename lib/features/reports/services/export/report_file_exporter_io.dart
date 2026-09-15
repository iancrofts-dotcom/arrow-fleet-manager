import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../report_export_result.dart';

Future<ReportExportResult> saveBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return ReportExportResult(message: 'Saved to ${file.path}');
}
