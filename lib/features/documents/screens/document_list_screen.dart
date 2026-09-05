import 'dart:io';

import 'package:open_filex/open_filex.dart';

import 'package:flutter/material.dart';

import '../../../shared/widgets/app_page_scaffold.dart';
import '../../auth/services/permission_service.dart';
import '../../vehicles/models/vehicle.dart';
import '../../vehicles/services/vehicle_service.dart';
import '../models/fleet_document.dart';
import '../services/document_service.dart';
import 'edit_document_screen.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final DocumentService _service = DocumentService();
  final VehicleService _vehicleService = VehicleService();

  late Future<_DocumentListData> _documentsFuture;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  void _loadDocuments() {
    _documentsFuture = _loadDocumentData();
  }

  Future<_DocumentListData> _loadDocumentData() async => _DocumentListData(
    documents: await _service.getAll(),
    vehicles: await _vehicleService.getVehicleMap(),
  );

  Future<void> _refresh() async {
    setState(() {
      _loadDocuments();
    });

    await _documentsFuture;
  }

  Future<void> _openDocument(FleetDocument document) async {
    if (document.filePath.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No file attached.')));
      return;
    }

    final file = File(document.filePath);

    if (!await file.exists()) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Attached file not found.')));
      return;
    }

    await OpenFilex.open(document.filePath);
  }

  Future<void> _addDocument() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const EditDocumentScreen()));
    if (created == true && mounted) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.instance.canViewVehicles) {
      return const _DocumentsAccessDenied();
    }

    return AppPageScaffold(
      title: 'Documents',
      subtitle: 'Fleet and compliance document records.',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDocument,
        icon: const Icon(Icons.add),
        label: const Text('Add Document'),
      ),
      child: FutureBuilder<_DocumentListData>(
        future: _documentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(label: 'Loading documents...');
          }

          if (snapshot.hasError) {
            return AppErrorState(
              message: 'Unable to load documents.',
              onRetry: _refresh,
            );
          }

          final data = snapshot.data;
          final allDocuments = data?.documents ?? const <FleetDocument>[];
          final permissions = PermissionService.instance;
          final documents = permissions.canViewDriverComplianceDocuments
              ? allDocuments
              : allDocuments
                    .where(
                      (document) =>
                          document.driverId == null ||
                          !document.category.isSingleCurrentComplianceCategory,
                    )
                    .toList();

          if (documents.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 96),
                  AppEmptyState(
                    title: 'No documents have been added.',
                    message:
                        'Documents will appear here when they are available.',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: documents.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final document = documents[index];

                final status = _service.status(document.expiryDate);

                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.description)),
                  title: Text(document.title),
                  subtitle: Text(_subtitleFor(document, data?.vehicles ?? {})),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (document.filePath.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.attach_file, size: 20),
                        ),
                      Chip(
                        label: Text(status),
                        backgroundColor: _statusColor(status),
                      ),
                    ],
                  ),
                  onTap: () => _openDocument(document),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Expired':
        return Colors.red.shade100;

      case 'Due Soon':
        return Colors.orange.shade100;

      default:
        return Colors.green.shade100;
    }
  }

  String _subtitleFor(FleetDocument document, Map<int, Vehicle> vehicles) {
    final vehicle = document.vehicleId == null
        ? null
        : vehicles[document.vehicleId!];
    final category = document.category.name.toUpperCase();
    if (vehicle == null) return category;
    return '$category • ${vehicle.registration} • ${vehicle.fleetNumber}';
  }
}

class _DocumentListData {
  const _DocumentListData({required this.documents, required this.vehicles});

  final List<FleetDocument> documents;
  final Map<int, Vehicle> vehicles;
}

class _DocumentsAccessDenied extends StatelessWidget {
  const _DocumentsAccessDenied();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Access Denied')),
    body: const Center(
      child: Text('You do not have permission to view fleet documents.'),
    ),
  );
}
