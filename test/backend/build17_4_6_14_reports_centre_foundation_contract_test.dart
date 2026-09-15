import 'dart:io';

import 'package:arrow_fleet_manager/features/reports/models/report_document.dart';
import 'package:arrow_fleet_manager/features/reports/services/report_csv_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Reports Centre exposes PDF and CSV export without SQLite coupling', () {
    final source = File(
      'lib/features/reports/screens/reports_screen.dart',
    ).readAsStringSync();

    expect(source, contains("title: 'Reports Centre'"));
    expect(source, contains("label: const Text('Preview PDF')"));
    expect(source, contains("label: const Text('Export PDF')"));
    expect(source, contains("label: const Text('Export CSV')"));
    expect(source, contains('ReportDocumentPdfService'));
    expect(source, contains('ReportCsvService'));
    expect(source, contains('ReportFileExporter'));
    expect(source, isNot(contains('AppDatabase')));
  });

  test('central Web enables Reports through the shared parity service', () {
    final source = File(
      'lib/app/router_feature_screens_web.dart',
    ).readAsStringSync();

    expect(source, contains('shared_reports.ReportsScreen'));
    expect(source, contains('CentralFleetReportService'));
    expect(source, contains('CentralResilienceRuntime.instance.run'));
    expect(
      source,
      isNot(contains('Central reporting is not enabled on Web yet')),
    );
  });

  test('report file export is platform isolated', () {
    final shared = File(
      'lib/features/reports/services/report_file_exporter.dart',
    ).readAsStringSync();
    final web = File(
      'lib/features/reports/services/export/report_file_exporter_web.dart',
    ).readAsStringSync();
    final native = File(
      'lib/features/reports/services/export/report_file_exporter_io.dart',
    ).readAsStringSync();

    expect(shared, contains('dart.library.io'));
    expect(shared, contains('dart.library.js_interop'));
    expect(shared, isNot(contains("import 'dart:io'")));
    expect(web, contains("import 'dart:js_interop'"));
    expect(web, isNot(contains("import 'dart:html'")));
    expect(web, contains("@JS('Blob')"));
    expect(web, contains("@JS('URL.createObjectURL')"));
    expect(native, contains("import 'dart:io'"));
  });

  test('CSV export escapes report values correctly', () {
    final document = ReportDocument(
      id: 'test',
      title: 'Fleet, Summary',
      subtitle: 'Test',
      generatedAt: DateTime.utc(2026, 9, 14),
      sections: const [
        ReportSection(
          title: 'Fleet',
          rows: [ReportRow(label: 'Note', value: 'Quoted "value"')],
        ),
      ],
    );

    final csv = const ReportCsvService().generate(document);
    expect(csv, contains('"Fleet, Summary"'));
    expect(csv, contains('"Quoted ""value"""'));
    expect(csv, contains('Section,Metric,Value'));

    final formulaDocument = ReportDocument(
      id: 'formula-test',
      title: '=HYPERLINK("https://example.invalid")',
      subtitle: 'Test',
      generatedAt: DateTime.utc(2026, 9, 14),
      sections: const [],
    );
    final formulaCsv = const ReportCsvService().generate(formulaDocument);
    expect(formulaCsv, contains("'=HYPERLINK"));
  });

  test('generic report document supports reusable modules', () {
    final model = File(
      'lib/features/reports/models/report_document.dart',
    ).readAsStringSync();
    final adapter = File(
      'lib/features/reports/services/fleet_report_document_adapter.dart',
    ).readAsStringSync();

    expect(model, contains('class ReportDocument'));
    expect(model, contains('class ReportSection'));
    expect(model, contains('class ReportRow'));
    expect(adapter, contains("id: 'fleet-summary'"));
    expect(adapter, contains("title: 'Compliance & Maintenance'"));
    expect(adapter, contains("title: 'Operations'"));
  });
}
