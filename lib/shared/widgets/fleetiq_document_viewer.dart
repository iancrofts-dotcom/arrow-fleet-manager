import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class FleetIqDocumentViewer extends StatelessWidget {
  const FleetIqDocumentViewer({
    super.key,
    required this.title,
    required this.fileName,
    required this.contentType,
    required this.bytes,
  });

  final String title;
  final String fileName;
  final String contentType;
  final Uint8List bytes;

  bool get _isPdf =>
      contentType.toLowerCase().contains('pdf') ||
      fileName.toLowerCase().endsWith('.pdf');

  bool get _isImage =>
      contentType.toLowerCase().startsWith('image/') ||
      RegExp(r'\.(png|jpe?g|webp)$', caseSensitive: false).hasMatch(fileName);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('document-viewer-close'),
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
        title: Text(title),
        actions: [
          if (_isPdf)
            IconButton(
              tooltip: 'Print',
              onPressed: () => Printing.layoutPdf(onLayout: (_) async => bytes),
              icon: const Icon(Icons.print_outlined),
            ),
          if (_isPdf)
            IconButton(
              tooltip: 'Share',
              onPressed: () =>
                  Printing.sharePdf(bytes: bytes, filename: fileName),
              icon: const Icon(Icons.share_outlined),
            ),
        ],
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (_isPdf) {
      return PdfPreview(
        build: (_) async => bytes,
        pdfFileName: fileName,
        allowPrinting: false,
        allowSharing: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      );
    }
    if (_isImage) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5,
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const _UnsupportedDocument(),
            ),
          ),
        ),
      );
    }
    return const _UnsupportedDocument();
  }
}

class _UnsupportedDocument extends StatelessWidget {
  const _UnsupportedDocument();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined, size: 54),
          SizedBox(height: 12),
          Text(
            'This file cannot be previewed inside FleetIQ. Use Share to open it in another app.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
