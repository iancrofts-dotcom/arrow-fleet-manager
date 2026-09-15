import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/report_document.dart';
import 'report_branding_service.dart';
import 'report_format_service.dart';

class ReportDocumentPdfService {
  const ReportDocumentPdfService();

  Future<Uint8List> generate(ReportDocument document) async {
    const branding = ReportBrandingService();
    const formatter = ReportFormatService();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${branding.footer} | ${branding.version}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        build: (context) => [
          pw.Text(
            branding.companyName,
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            document.title,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(document.subtitle),
          pw.SizedBox(height: 6),
          pw.Text('Generated: ${formatter.formatDate(document.generatedAt)}'),
          pw.SizedBox(height: 18),
          ...document.sections.expand(
            (section) => <pw.Widget>[
              pw.Text(
                section.title,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(1),
                },
                children: section.rows
                    .map(
                      (row) => pw.TableRow(
                        children: [
                          _cell(row.label),
                          _cell(row.value, alignRight: true),
                        ],
                      ),
                    )
                    .toList(),
              ),
              pw.SizedBox(height: 16),
            ],
          ),
        ],
      ),
    );

    return Uint8List.fromList(await pdf.save());
  }

  pw.Widget _cell(String value, {bool alignRight = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: pw.Align(
      alignment: alignRight
          ? pw.Alignment.centerRight
          : pw.Alignment.centerLeft,
      child: pw.Text(value),
    ),
  );
}
