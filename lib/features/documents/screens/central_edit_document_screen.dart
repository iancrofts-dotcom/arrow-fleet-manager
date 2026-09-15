import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../backend/backend_client.dart';
import '../../../backend/documents/central_document_repository.dart';
import '../../../backend/documents/supabase_central_document_gateway.dart';
import '../../../backend/drivers/backend_driver.dart';
import '../../../backend/drivers/backend_driver_repository.dart';
import '../../../backend/drivers/supabase_driver_gateway.dart';
import '../../../backend/vehicles/backend_vehicle.dart';
import '../../../backend/vehicles/backend_vehicle_repository.dart';
import '../../../backend/vehicles/supabase_vehicle_gateway.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/permission_service.dart';

class CentralEditDocumentScreen extends StatefulWidget {
  const CentralEditDocumentScreen({
    super.key,
    this.repository,
    this.initialEntityType,
    this.initialEntityId,
    this.initialOwnerLabel,
    this.lockOwner = false,
  });

  final CentralDocumentRepository? repository;
  final String? initialEntityType;
  final String? initialEntityId;
  final String? initialOwnerLabel;
  final bool lockOwner;

  @override
  State<CentralEditDocumentScreen> createState() =>
      _CentralEditDocumentScreenState();
}

class _CentralEditDocumentScreenState extends State<CentralEditDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _caption = TextEditingController();
  late final CentralDocumentRepository _repository;
  late Future<_Subjects> _subjectsFuture;

  String _entityType = 'vehicle';
  String? _entityId;
  String _category = 'Other';
  DateTime? _expiresOn;
  PlatformFile? _file;
  bool _saving = false;

  static const _vehicleCategories = <String>[
    'Insurance',
    'Road Tax',
    'MOT',
    'Service',
    'Taxi Plate',
    'V5 / Registration',
    'Lease / Finance',
    'Other',
  ];
  static const _driverCategories = <String>[
    'Driving Licence',
    'CPC',
    'Medical',
    'DBS',
    'Taxi Licence',
    'Training',
    'Other',
  ];
  static const _generalCategories = <String>[
    'Policy',
    'Insurance',
    'Procedure',
    'Certificate',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ??
        const CentralDocumentRepository(SupabaseCentralDocumentGateway());
    final permissions = PermissionService.instance;
    final ownDriverId = AuthService.instance.currentBackendDriverId;
    if (widget.initialEntityType != null) {
      _entityType = widget.initialEntityType!;
      _entityId = widget.initialEntityId;
    } else if (permissions.isDriver && ownDriverId != null) {
      _entityType = 'driver';
      _entityId = ownDriverId;
    }
    _category = _categories.last;
    _subjectsFuture = _loadSubjects();
  }

  @override
  void dispose() {
    _title.dispose();
    _caption.dispose();
    super.dispose();
  }

  Future<_Subjects> _loadSubjects() async {
    final permissions = PermissionService.instance;
    final vehicles = permissions.canViewVehicles
        ? await BackendVehicleRepository(
            SupabaseVehicleGateway(),
          ).listVehicles()
        : const <BackendVehicle>[];
    final drivers = permissions.canViewDriverComplianceDocuments
        ? await BackendDriverRepository(SupabaseDriverGateway()).listDrivers()
        : const <BackendDriver>[];
    return _Subjects(
      vehicles: vehicles.where((item) => item.isActive).toList(growable: false),
      drivers: drivers.where((item) => item.isActive).toList(growable: false),
    );
  }

  List<String> get _categories => switch (_entityType) {
    'driver' => _driverCategories,
    'general' => _generalCategories,
    _ => _vehicleCategories,
  };

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.single;
    if (file.bytes == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to read the selected file.')),
      );
      return;
    }
    if (file.size <= 0 || file.size > 10 * 1024 * 1024) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documents must be 10 MB or smaller.')),
      );
      return;
    }
    setState(() {
      _file = file;
      if (_title.text.trim().isEmpty) {
        _title.text = file.name.replaceFirst(RegExp(r'\.[^.]+$'), '');
      }
    });
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresOn ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2150),
    );
    if (picked != null) setState(() => _expiresOn = picked);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }
    final file = _file;
    if (file?.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a document to upload.')),
      );
      return;
    }
    final subjectId = _entityType == 'general'
        ? BackendClient.client.auth.currentUser?.id
        : _entityId;
    if (subjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select the document owner.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _repository.uploadDocument(
        entityType: _entityType,
        entityId: subjectId,
        title: _title.text.trim(),
        category: _category,
        fileName: file!.name,
        bytes: file.bytes!,
        contentType: _contentType(file.extension),
        expiresOn: _expiresOn,
        caption: _caption.text.trim(),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to upload document. Check your connection and permissions, then try again.',
          ),
        ),
      );
      setState(() => _saving = false);
      return;
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final permissions = PermissionService.instance;
    return AppPageScaffold(
      title: 'Add Document',
      subtitle: 'Upload a central FleetIQ document.',
      child: FutureBuilder<_Subjects>(
        future: _subjectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(label: 'Loading fleet records...');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              message: 'Unable to load document owners.',
              onRetry: () async =>
                  setState(() => _subjectsFuture = _loadSubjects()),
            );
          }
          final subjects = snapshot.data!;
          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SectionCard(
                  title: 'Document owner',
                  child: Column(
                    children: [
                      if (widget.lockOwner || permissions.isDriver)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            _entityType == 'driver'
                                ? Icons.person_outline
                                : Icons.local_shipping_outlined,
                          ),
                          title: Text(
                            widget.initialOwnerLabel ??
                                (_entityType == 'driver'
                                    ? 'My Driver Record'
                                    : 'Selected Fleet Record'),
                          ),
                          subtitle: Text(
                            _entityType == 'driver' ? 'Driver' : 'Vehicle',
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          initialValue: _entityType,
                          decoration: const InputDecoration(labelText: 'Type'),
                          items: [
                            const DropdownMenuItem(
                              value: 'vehicle',
                              child: Text('Vehicle'),
                            ),
                            if (permissions.canViewDriverComplianceDocuments)
                              const DropdownMenuItem(
                                value: 'driver',
                                child: Text('Driver'),
                              ),
                            const DropdownMenuItem(
                              value: 'general',
                              child: Text('General fleet'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _entityType = value;
                              _entityId = null;
                              _category = _categories.last;
                            });
                          },
                        ),
                      if (_entityType == 'vehicle' &&
                          !widget.lockOwner &&
                          !permissions.isDriver) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _entityId,
                          decoration: const InputDecoration(
                            labelText: 'Vehicle',
                          ),
                          items: subjects.vehicles
                              .map(
                                (vehicle) => DropdownMenuItem(
                                  value: vehicle.id,
                                  child: Text(
                                    '${vehicle.registration} • ${vehicle.fleetNumber}',
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          validator: (value) =>
                              value == null ? 'Select a vehicle' : null,
                          onChanged: (value) =>
                              setState(() => _entityId = value),
                        ),
                      ],
                      if (_entityType == 'driver' &&
                          !widget.lockOwner &&
                          !permissions.isDriver) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _entityId,
                          decoration: const InputDecoration(
                            labelText: 'Driver',
                          ),
                          items: subjects.drivers
                              .map(
                                (driver) => DropdownMenuItem(
                                  value: driver.id,
                                  child: Text(
                                    '${driver.firstName} ${driver.lastName}',
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          validator: (value) =>
                              value == null ? 'Select a driver' : null,
                          onChanged: (value) =>
                              setState(() => _entityId = value),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Document details',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _title,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter a document title'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        key: ValueKey(_entityType),
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: _categories
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) setState(() => _category = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _caption,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_outlined),
                        title: const Text('Expiry date'),
                        subtitle: Text(
                          _expiresOn == null ? 'No expiry' : _date(_expiresOn!),
                        ),
                        trailing: Wrap(
                          children: [
                            if (_expiresOn != null)
                              IconButton(
                                tooltip: 'Clear expiry',
                                onPressed: () =>
                                    setState(() => _expiresOn = null),
                                icon: const Icon(Icons.clear),
                              ),
                            IconButton(
                              tooltip: 'Choose expiry',
                              onPressed: _pickExpiry,
                              icon: const Icon(Icons.calendar_month_outlined),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Attachment',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _saving ? null : _pickFile,
                        icon: const Icon(Icons.attach_file),
                        label: Text(
                          _file == null ? 'Choose File' : 'Change File',
                        ),
                      ),
                      if (_file != null) ...[
                        const SizedBox(height: 10),
                        Text('${_file!.name} • ${_size(_file!.size)}'),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(_saving ? 'Uploading...' : 'Upload Document'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Subjects {
  const _Subjects({required this.vehicles, required this.drivers});
  final List<BackendVehicle> vehicles;
  final List<BackendDriver> drivers;
}

String _contentType(String? extension) => switch (extension?.toLowerCase()) {
  'jpg' || 'jpeg' => 'image/jpeg',
  'png' => 'image/png',
  'webp' => 'image/webp',
  'pdf' => 'application/pdf',
  _ => 'application/octet-stream',
};

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _size(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
  return '$bytes B';
}
