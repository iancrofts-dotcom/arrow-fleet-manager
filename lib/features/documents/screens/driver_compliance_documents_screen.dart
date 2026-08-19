import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../../shared/widgets/app_page_scaffold.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/permission_service.dart';
import '../../drivers/models/driver_compliance.dart';
import '../../drivers/services/driver_compliance_service.dart';
import '../models/fleet_document.dart';
import '../services/document_service.dart';

/// Evidence access is re-checked from the authenticated driver ID rather than
/// trusting the route argument supplied by a caller.
class DriverComplianceDocumentsScreen extends StatefulWidget {
  const DriverComplianceDocumentsScreen({
    super.key,
    required this.driverId,
  });

  final int driverId;

  static String _formatDate(DateTime? value) => _documentDate(value);

  @override
  State<DriverComplianceDocumentsScreen> createState() =>
      _DriverComplianceDocumentsScreenState();
}

class _DriverComplianceDocumentsScreenState
    extends State<DriverComplianceDocumentsScreen> {
  final DocumentService _documents = DocumentService();
  final DriverComplianceService _complianceService = DriverComplianceService();
  late Future<_EvidenceData> _future;

  static const _categories = [
    DocumentCategory.licence,
    DocumentCategory.cpc,
    DocumentCategory.medical,
    DocumentCategory.dbs,
    DocumentCategory.tachographCard,
  ];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  bool get _canAccess {
    final permissions = PermissionService.instance;
    return permissions.canViewDriverComplianceDocuments ||
        (permissions.canViewOwnComplianceDocuments &&
            AuthService.instance.currentDriverId == widget.driverId);
  }

  Future<_EvidenceData> _load() async {
    final compliance =
        await _complianceService.getByDriverId(widget.driverId);
    final documents = await _documents.getCurrentComplianceDocuments(widget.driverId);
    return _EvidenceData(compliance: compliance, documents: documents);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _upload(
    DocumentCategory category,
    DriverCompliance? compliance,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    final selectedPath = result?.files.single.path;
    if (selectedPath == null) return;

    try {
      await _documents.uploadComplianceEvidence(
        driverId: widget.driverId,
        category: category,
        sourceFile: File(selectedPath),
        title: _documentCategoryTitle(category),
        expirySnapshot: _expiryFor(category, compliance),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compliance evidence uploaded.')),
      );
      await _refresh();
    } on FileSystemException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document file could not be found.')),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message.toString())),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save compliance evidence.')),
      );
    }
  }

  Future<void> _uploadOther() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    final selectedPath = result?.files.single.path;
    if (selectedPath == null || !mounted) return;
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Other Compliance Document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Document title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text), child: const Text('Upload')),
        ],
      ),
    );
    controller.dispose();
    if (title == null) return;
    try {
      await _documents.uploadComplianceEvidence(
        driverId: widget.driverId,
        category: DocumentCategory.other,
        sourceFile: File(selectedPath),
        title: title,
        expirySnapshot: null,
      );
      if (!mounted) return;
      await _refresh();
    } on FileSystemException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document file could not be found.')));
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message.toString())));
    }
  }

  Future<void> _open(FleetDocument document) async {
    final file = File(document.filePath);
    if (!await file.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document file could not be found.')),
      );
      return;
    }
    await OpenFilex.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    if (!_canAccess) {
      return const Scaffold(
        body: AppEmptyState(
          icon: Icons.lock_outline,
          title: 'Access denied',
          message: 'You do not have access to these compliance documents.',
        ),
      );
    }
    return AppPageScaffold(
      title: 'Compliance Evidence',
      subtitle: 'Current evidence and archived replacement history.',
      child: FutureBuilder<_EvidenceData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(label: 'Loading compliance evidence...');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              message: 'Unable to load compliance evidence.',
              onRetry: () => setState(() => _future = _load()),
            );
          }
          final data = snapshot.data!;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              ..._categories.map((category) {
                final document = data.documentFor(category);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_documentCategoryTitle(category), style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('Expiry: ${_documentDate(_expiryFor(category, data.compliance))}'),
                        Text('Status: ${_complianceService.status(_expiryFor(category, data.compliance))}'),
                        Text('Evidence: ${document == null ? 'Missing' : 'Uploaded'}'),
                        if (document != null) ...[
                          const SizedBox(height: 4),
                          Text(document.originalFileName ?? document.title,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          if (document != null)
                            OutlinedButton.icon(
                              onPressed: () => _open(document),
                              icon: const Icon(Icons.visibility_outlined),
                              label: const Text('View Document'),
                            ),
                          FilledButton.tonalIcon(
                            onPressed: () => _upload(category, data.compliance),
                            icon: Icon(document == null ? Icons.upload_file_outlined : Icons.swap_horiz_outlined),
                            label: Text(document == null ? 'Upload Document' : 'Replace Document'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DriverComplianceDocumentHistoryScreen(
                                  driverId: widget.driverId,
                                  category: category,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.history_outlined),
                            label: const Text('View History'),
                          ),
                        ]),
                      ],
                    ),
                  ),
                );
              }),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Other Compliance Documents', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...data.documents.where((document) => document.category == DocumentCategory.other).map(
                      (document) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(document.originalFileName ?? document.title),
                        subtitle: const Text('Current evidence'),
                        trailing: IconButton(
                          tooltip: 'View document',
                          onPressed: () => _open(document),
                          icon: const Icon(Icons.visibility_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      onPressed: _uploadOther,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('Upload Other Compliance Document'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static DateTime? _expiryFor(DocumentCategory category, DriverCompliance? value) => switch (category) {
        DocumentCategory.licence => value?.licenceExpiry,
        DocumentCategory.cpc => value?.cpcExpiry,
        DocumentCategory.medical => value?.medicalExpiry,
        DocumentCategory.dbs => value?.dbsExpiry,
        _ => null,
      };

}

class DriverComplianceDocumentHistoryScreen extends StatelessWidget {
  const DriverComplianceDocumentHistoryScreen({
    super.key,
    required this.driverId,
    required this.category,
  });

  final int driverId;
  final DocumentCategory category;

  @override
  Widget build(BuildContext context) {
    final service = DocumentService();
    return AppPageScaffold(
      title: 'Evidence History',
      subtitle: _documentCategoryTitle(category),
      child: FutureBuilder<List<FleetDocument>>(
        future: service.getComplianceDocumentHistory(driverId, category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const AppLoadingState(label: 'Loading document history...');
          if (snapshot.hasError) return const AppErrorState(message: 'Unable to load document history.');
          final documents = snapshot.data!;
          if (documents.isEmpty) return const AppEmptyState(title: 'No evidence history', message: 'No evidence has been uploaded for this category.');
          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: documents.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final document = documents[index];
              return SectionCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(document.isArchived ? Icons.archive_outlined : Icons.check_circle_outline),
                  title: Text(document.originalFileName ?? document.title),
                  subtitle: Text('${document.isArchived ? 'ARCHIVED' : 'CURRENT'} • Uploaded ${DriverComplianceDocumentsScreen._formatDate(document.lastUpdated)}\nExpiry snapshot: ${DriverComplianceDocumentsScreen._formatDate(document.expiryDate)}${document.archivedAt == null ? '' : '\nArchived ${DriverComplianceDocumentsScreen._formatDate(document.archivedAt)}'}${document.uploadedByUserId == null ? '' : '\nUploaded by ID ${document.uploadedByUserId}'}'),
                  trailing: IconButton(
                    tooltip: 'View document',
                    onPressed: () async {
                      final file = File(document.filePath);
                      if (!await file.exists()) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document file could not be found.')));
                        return;
                      }
                      await OpenFilex.open(file.path);
                    },
                    icon: const Icon(Icons.visibility_outlined),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EvidenceData {
  const _EvidenceData({required this.compliance, required this.documents});
  final DriverCompliance? compliance;
  final List<FleetDocument> documents;
  FleetDocument? documentFor(DocumentCategory category) {
    for (final document in documents) {
      if (document.category == category) return document;
    }
    return null;
  }
}

String _documentCategoryTitle(DocumentCategory category) => switch (category) {
      DocumentCategory.licence => 'Driving Licence',
      DocumentCategory.cpc => 'CPC',
      DocumentCategory.medical => 'Medical',
      DocumentCategory.dbs => 'DBS',
      DocumentCategory.tachographCard => 'Tachograph Card',
      DocumentCategory.other => 'Other Compliance',
      _ => category.name,
    };

String _documentDate(DateTime? value) => value == null
    ? 'Not Recorded'
    : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
