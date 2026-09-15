import 'dart:js_interop';
import 'dart:typed_data';

import '../report_export_result.dart';

@JS('Blob')
extension type _BrowserBlob._(JSObject _) implements JSObject {
  external factory _BrowserBlob(JSArray<JSAny?> parts, [JSObject? options]);
}

@JS('URL.createObjectURL')
external String _createObjectUrl(JSObject object);

@JS('URL.revokeObjectURL')
external void _revokeObjectUrl(String url);

@JS('document')
external _BrowserDocument get _document;

extension type _BrowserDocument._(JSObject _) implements JSObject {
  external _BrowserElement? get body;
  external _BrowserElement createElement(String localName);
}

extension type _BrowserElement._(JSObject _) implements JSObject {
  external JSObject appendChild(JSObject node);
  external void setAttribute(String name, String value);
  external void click();
  external void remove();
}

Future<ReportExportResult> saveBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  final parts = <JSAny?>[bytes.toJS].toJS;
  final options = <String, Object?>{'type': mimeType}.jsify() as JSObject;
  final blob = _BrowserBlob(parts, options);
  final url = _createObjectUrl(blob);
  final anchor = _document.createElement('a')
    ..setAttribute('href', url)
    ..setAttribute('download', fileName)
    ..setAttribute('style', 'display:none');

  try {
    _document.body?.appendChild(anchor);
    anchor.click();
  } finally {
    anchor.remove();
    _revokeObjectUrl(url);
  }

  return ReportExportResult(message: '$fileName downloaded.');
}
