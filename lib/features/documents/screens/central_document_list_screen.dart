import 'package:flutter/material.dart';
import '../../../backend/documents/backend_fleet_document.dart';
import '../../../backend/documents/central_document_repository.dart';
import '../../../backend/documents/supabase_central_document_gateway.dart';
import '../../../backend/drivers/backend_driver.dart';
import '../../../backend/drivers/backend_driver_repository.dart';
import '../../../backend/drivers/supabase_driver_gateway.dart';
import '../../../backend/vehicles/backend_vehicle_repository.dart';
import '../../../backend/vehicles/supabase_vehicle_gateway.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/fleetiq_document_viewer.dart';
import '../../auth/services/permission_service.dart';
import 'central_edit_document_screen.dart';

class CentralDocumentListScreen extends StatefulWidget {
  const CentralDocumentListScreen({
    super.key,
    this.repository,
    this.initialFilter = 'All',
    this.entityType,
    this.entityId,
    this.ownerLabel,
  });

  final CentralDocumentRepository? repository;
  final String initialFilter;
  final String? entityType;
  final String? entityId;
  final String? ownerLabel;

  @override
  State<CentralDocumentListScreen> createState() =>
      _CentralDocumentListScreenState();
}

class _CentralDocumentListScreenState extends State<CentralDocumentListScreen> {
  late final CentralDocumentRepository _repository;
  final TextEditingController _search = TextEditingController();
  late Future<_DocumentListData> _future;
  late String _filter;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ??
        const CentralDocumentRepository(SupabaseCentralDocumentGateway());
    _filter = widget.initialFilter;
    _reload();
    _search.addListener(_searchChanged);
  }

  @override
  void dispose() {
    _search
      ..removeListener(_searchChanged)
      ..dispose();
    super.dispose();
  }

  void _searchChanged() => setState(() {});

  void _reload() {
    _future = _loadData();
  }

  Future<_DocumentListData> _loadData() async {
    final documentsFuture = _repository.listDocuments(includeArchived: true);
    final isOwnerLocked = widget.entityType != null && widget.entityId != null;

    if (isOwnerLocked) {
      return _DocumentListData(
        documents: await documentsFuture,
        vehicleNames: const {},
        driverNames: const {},
        lockedOwnerLabel: widget.ownerLabel,
      );
    }

    final permissions = PermissionService.instance;
    final vehiclesFuture = BackendVehicleRepository(
      SupabaseVehicleGateway(),
    ).listVehicles();
    final driversFuture = permissions.canViewDriverComplianceDocuments
        ? BackendDriverRepository(SupabaseDriverGateway()).listDrivers()
        : Future.value(const <BackendDriver>[]);
    final documents = await documentsFuture;
    final vehicles = await vehiclesFuture;
    final drivers = await driversFuture;
    return _DocumentListData(
      documents: documents,
      vehicleNames: {for (final item in vehicles) item.id: item.registration},
      driverNames: {
        for (final item in drivers)
          item.id: '${item.firstName} ${item.lastName}',
      },
    );
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  Future<void> _addDocument() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CentralEditDocumentScreen(
          repository: _repository,
          initialEntityType: widget.entityType,
          initialEntityId: widget.entityId,
          initialOwnerLabel: widget.ownerLabel,
          lockOwner: widget.entityType != null && widget.entityId != null,
        ),
      ),
    );
    if (created == true && mounted) await _refresh();
  }

  Future<void> _openDocument(BackendFleetDocument document) async {
    try {
      final bytes = await _repository.downloadDocument(document.storagePath);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => FleetIqDocumentViewer(
            title: document.title.trim().isEmpty
                ? document.fileName
                : document.title,
            fileName: document.fileName,
            contentType: document.contentType,
            bytes: bytes,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open attached document.\n$error')),
      );
    }
  }

  Future<void> _archive(BackendFleetDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Document'),
        content: Text(
          'Archive ${document.title.isEmpty ? document.fileName : document.title}?\n\n'
          'The file is retained in FleetIQ history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await _repository.archiveDocument(document.id);
      if (mounted) await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to archive document.\n$error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = PermissionService.instance;
    if (!permissions.canViewVehicles &&
        !permissions.canViewDriverComplianceDocuments &&
        !permissions.canViewOwnComplianceDocuments) {
      return const Scaffold(
        body: Center(
          child: Text('You do not have permission to view documents.'),
        ),
      );
    }

    return AppPageScaffold(
      title: widget.ownerLabel == null
          ? 'Documents'
          : '${widget.ownerLabel} Documents',
      subtitle: widget.ownerLabel == null
          ? 'Fleet and compliance document records.'
          : 'Central documents linked to ${widget.ownerLabel}.',
      floatingActionButton:
          (permissions.canViewVehicles ||
              permissions.canManageDriverComplianceDocuments ||
              permissions.canViewOwnComplianceDocuments)
          ? FloatingActionButton.extended(
              onPressed: _addDocument,
              icon: const Icon(Icons.add),
              label: const Text('Add Document'),
            )
          : null,
      child: Column(
        children: [
          SectionCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'Search documents...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (widget.entityType == null || widget.entityId == null)
                        for (final value in const [
                          'All',
                          'Vehicle',
                          'Driver',
                          'General',
                          'Workshop',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(value),
                              selected: _filter == value,
                              onSelected: (_) =>
                                  setState(() => _filter = value),
                            ),
                          ),
                      FilterChip(
                        label: const Text('Archived'),
                        selected: _showArchived,
                        onSelected: (value) =>
                            setState(() => _showArchived = value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<_DocumentListData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoadingState(label: 'Loading documents...');
                }
                if (snapshot.hasError) {
                  return AppErrorState(
                    title: 'Unable to load Documents',
                    message: 'Central document records could not be loaded.',
                    onRetry: _refresh,
                  );
                }
                final data = snapshot.data!;
                final query = _search.text.trim().toLowerCase();
                final documents = data.documents
                    .where((document) {
                      if (widget.entityType != null &&
                          document.entityType != widget.entityType) {
                        return false;
                      }
                      if (widget.entityId != null &&
                          document.entityId != widget.entityId) {
                        return false;
                      }
                      if (!_showArchived && document.isArchived) {
                        return false;
                      }
                      if (_showArchived && !document.isArchived) {
                        return false;
                      }
                      if (_filter != 'All' &&
                          _entityFilter(document.entityType) != _filter) {
                        return false;
                      }
                      if (query.isEmpty) {
                        return true;
                      }
                      final owner = data.owner(document).toLowerCase();
                      return document.title.toLowerCase().contains(query) ||
                          document.fileName.toLowerCase().contains(query) ||
                          document.category.toLowerCase().contains(query) ||
                          owner.contains(query);
                    })
                    .toList(growable: false);

                if (documents.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 96),
                        AppEmptyState(
                          icon: Icons.folder_outlined,
                          title: 'No documents found',
                          message: 'Upload a document or change the filters.',
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
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final document = documents[index];
                      final status = _status(document.expiresOn);
                      final canArchive =
                          !document.isArchived &&
                          const {
                            'vehicle',
                            'driver',
                            'general',
                          }.contains(document.entityType);
                      return ListTile(
                        leading: CircleAvatar(
                          child: Icon(
                            document.contentType.startsWith('image/')
                                ? Icons.image_outlined
                                : Icons.description_outlined,
                          ),
                        ),
                        title: Text(
                          document.title.isEmpty
                              ? document.fileName
                              : document.title,
                        ),
                        subtitle: Text(
                          '${document.category} • ${data.owner(document)}'
                          '${document.expiresOn == null ? '' : ' • Expires ${_date(document.expiresOn!)}'}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(
                                document.isArchived ? 'Archived' : status,
                              ),
                              backgroundColor: _statusColor(
                                context,
                                document.isArchived ? 'Archived' : status,
                              ),
                            ),
                            if (canArchive)
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'archive') _archive(document);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'archive',
                                    child: Text('Archive'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        onTap: document.isArchived
                            ? null
                            : () => _openDocument(document),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentListData {
  const _DocumentListData({
    required this.documents,
    required this.vehicleNames,
    required this.driverNames,
    this.lockedOwnerLabel,
  });

  final List<BackendFleetDocument> documents;
  final Map<String, String> vehicleNames;
  final Map<String, String> driverNames;
  final String? lockedOwnerLabel;

  String owner(BackendFleetDocument document) {
    final locked = lockedOwnerLabel?.trim();
    if (locked != null && locked.isNotEmpty) {
      return locked;
    }
    return switch (document.entityType) {
      'vehicle' => vehicleNames[document.entityId] ?? 'Vehicle',
      'driver' => driverNames[document.entityId] ?? 'Driver',
      'workshopInspectionItem' || 'workshopInspection' => 'Workshop',
      _ => 'Fleet',
    };
  }
}

String _entityFilter(String value) => switch (value) {
  'vehicle' => 'Vehicle',
  'driver' => 'Driver',
  'workshopInspectionItem' || 'workshopInspection' => 'Workshop',
  _ => 'General',
};

String _status(DateTime? expiry) {
  if (expiry == null) {
    return 'Current';
  }
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(expiry.year, expiry.month, expiry.day);
  if (day.isBefore(today)) {
    return 'Expired';
  }
  if (day.difference(today).inDays <= 30) {
    return 'Due Soon';
  }
  return 'Current';
}

Color _statusColor(BuildContext context, String status) => switch (status) {
  'Expired' => Colors.red.shade100,
  'Due Soon' => Colors.orange.shade100,
  'Archived' => Theme.of(context).colorScheme.surfaceContainerHighest,
  _ => Colors.green.shade100,
};

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
