import '../models/report_document.dart';

class ReportCsvService {
  const ReportCsvService();

  String generate(ReportDocument document) {
    final lines = <String>[
      _line(['Report', document.title]),
      _line(['Generated', document.generatedAt.toIso8601String()]),
      '',
      _line(['Section', 'Metric', 'Value']),
    ];

    for (final section in document.sections) {
      for (final row in section.rows) {
        lines.add(_line([section.title, row.label, row.value]));
      }
    }

    return '${lines.join('\r\n')}\r\n';
  }

  String _line(List<String> values) => values.map(_escape).join(',');

  String _escape(String value) {
    final safe = _neutralizeFormula(value);
    final escaped = safe.replaceAll('"', '""');
    if (escaped.contains(',') ||
        escaped.contains('"') ||
        escaped.contains('\n') ||
        escaped.contains('\r')) {
      return '"$escaped"';
    }
    return escaped;
  }

  String _neutralizeFormula(String value) {
    if (value.isEmpty) return value;
    final first = value.codeUnitAt(0);
    if (first == 0x3D || // =
        first == 0x2B || // +
        first == 0x2D || // -
        first == 0x40 || // @
        first == 0x09) {
      return "'$value";
    }
    return value;
  }
}
