import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../backend/workshop/backend_workshop_evidence.dart';
import '../../../backend/workshop/backend_workshop_inspection.dart';
import '../../../backend/workshop/backend_workshop_repair_job.dart';
import '../../../backend/workshop/backend_workshop_repository.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../services/central_workshop_pdf_service.dart';

class CentralWorkshopJobCardViewerScreen extends StatefulWidget {
  const CentralWorkshopJobCardViewerScreen({
    super.key,
    required this.job,
    required this.inspection,
    required this.evidence,
    required this.repository,
  });

  final BackendWorkshopRepairJob job;
  final BackendWorkshopInspection? inspection;
  final List<BackendWorkshopEvidence> evidence;
  final BackendWorkshopRepository repository;

  @override
  State<CentralWorkshopJobCardViewerScreen> createState() =>
      _CentralWorkshopJobCardViewerScreenState();
}

class _CentralWorkshopJobCardViewerScreenState
    extends State<CentralWorkshopJobCardViewerScreen> {
  final Map<String, Uint8List> _evidenceBytes = <String, Uint8List>{};
  bool _loadingEvidence = false;
  bool _creatingPdf = false;

  @override
  void initState() {
    super.initState();
    _loadEvidence();
  }

  Future<void> _loadEvidence() async {
    if (_loadingEvidence) return;
    _loadingEvidence = true;
    if (mounted) setState(() {});
    try {
      for (final evidence in widget.evidence) {
        if (!evidence.contentType.toLowerCase().startsWith('image/')) continue;
        if (_evidenceBytes.containsKey(evidence.id)) continue;
        try {
          final bytes = await widget.repository.downloadEvidence(
            evidence.storagePath,
          );
          if (!mounted) return;
          setState(() => _evidenceBytes[evidence.id] = bytes);
        } catch (_) {
          // A missing evidence object must never block the job card itself.
        }
      }
    } finally {
      _loadingEvidence = false;
      if (mounted) setState(() {});
    }
  }

  Future<Uint8List?> _createPdf() async {
    if (_creatingPdf) return null;
    final inspection = widget.inspection;
    if (inspection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The source inspection is not available yet. The Job Card can be viewed, but PDF export needs the source inspection.',
          ),
        ),
      );
      return null;
    }
    setState(() => _creatingPdf = true);
    try {
      await _loadEvidence();
      return await const CentralWorkshopPdfService().jobCard(
        job: widget.job,
        inspection: inspection,
        evidence: widget.evidence,
        evidenceBytes: _evidenceBytes,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to create PDF job card: $error')),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _creatingPdf = false);
    }
  }

  Future<void> _print() async {
    final bytes = await _createPdf();
    if (bytes == null) return;
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _share() async {
    final bytes = await _createPdf();
    if (bytes == null) return;
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${widget.job.jobNumber}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final inspection = widget.inspection;
    final evidence = widget.evidence;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('job-card-viewer-close'),
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
        title: Text('Job Card ${job.jobNumber}'),
        actions: [
          IconButton(
            tooltip: 'Print',
            onPressed: _creatingPdf ? null : _print,
            icon: const Icon(Icons.print_outlined),
          ),
          IconButton(
            tooltip: 'Share / download',
            onPressed: _creatingPdf ? null : _share,
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_creatingPdf) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
            ],
            SectionCard(
              title: 'Repair Job',
              subtitle: '${job.vehicleRegistration} · ${_label(job.status)}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _line('Job number', job.jobNumber),
                  _line('Vehicle', job.vehicleRegistration),
                  _line('Repair', job.title),
                  _line('Defect / description', job.description),
                  _line('Priority', _label(job.priority)),
                  _line('Status', _label(job.status)),
                  _line(
                    'Technician',
                    job.technicianName.trim().isEmpty
                        ? 'Unassigned'
                        : job.technicianName,
                  ),
                  _line('Work notes', job.workNotes),
                  _line('Parts notes', job.partsNotes),
                  _line('Actual hours', job.actualHours.toStringAsFixed(1)),
                  _line('Actual cost', '£${job.actualCost.toStringAsFixed(2)}'),
                  _line('Roadworthy', job.roadworthy ? 'Yes' : 'No'),
                  if (job.signedOffName.trim().isNotEmpty)
                    _line('Signed off by', job.signedOffName),
                  if (job.signedOffAt != null)
                    _line('Signed off', _date(job.signedOffAt!)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (inspection != null)
              SectionCard(
                title: 'Source Inspection',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line('Inspection', inspection.inspectionNumber),
                    _line('Type', _label(inspection.inspectionType)),
                    _line('Started', _date(inspection.dateStarted)),
                    _line(
                      'Driver / inspector',
                      inspection.driverName?.trim().isNotEmpty == true
                          ? inspection.driverName!
                          : inspection.technicianName,
                    ),
                    _line('Inspection mileage', inspection.mileage.toString()),
                    _line(
                      'Technician mileage',
                      job.technicianMileage?.toString() ?? 'Not recorded',
                    ),
                    _line('Inspection notes', inspection.notes),
                  ],
                ),
              )
            else
              const SectionCard(
                variant: SectionCardVariant.alert,
                title: 'Source Inspection',
                child: Text(
                  'FleetIQ could not read the source inspection for this repair. The repair Job Card is still available. Source inspection access is being restored by the current Workshop permission update.',
                ),
              ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Defect Evidence',
              subtitle: evidence.isEmpty
                  ? 'No evidence linked to this repair.'
                  : '${evidence.length} file(s) linked to this repair',
              child: evidence.isEmpty
                  ? const Text(
                      'No photos or evidence are linked to this defect.',
                    )
                  : Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final item in evidence) _evidenceCard(item),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _creatingPdf ? null : _print,
              icon: const Icon(Icons.print_outlined),
              label: const Text('Print Job Card'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _creatingPdf ? null : _share,
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share / Download PDF'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _evidenceCard(BackendWorkshopEvidence item) {
    final bytes = _evidenceBytes[item.id];
    final isImage = item.contentType.toLowerCase().startsWith('image/');
    return SizedBox(
      width: 260,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 170,
              width: double.infinity,
              child: isImage && bytes != null
                  ? InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4,
                      child: Image.memory(bytes, fit: BoxFit.cover),
                    )
                  : Center(
                      child: _loadingEvidence && isImage
                          ? const CircularProgressIndicator()
                          : const Icon(Icons.description_outlined, size: 46),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.fileName),
                  if (item.caption.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(item.caption),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 460) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(value.trim().isEmpty ? '—' : value),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(child: Text(value.trim().isEmpty ? '—' : value)),
          ],
        );
      },
    ),
  );

  static String _label(String value) => value
      .replaceAll('_', ' ')
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match[1]} ${match[2]}',
      );

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
