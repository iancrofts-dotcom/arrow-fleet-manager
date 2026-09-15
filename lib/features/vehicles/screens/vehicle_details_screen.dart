import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../assignments/repositories/assignment_repository.dart';
import '../../auth/services/permission_service.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/status_badge.dart';

import '../../drivers/models/driver.dart';
import '../../drivers/screens/assign_driver_screen.dart';
import '../../drivers/screens/assignment_history_screen.dart';
import '../../documents/models/fleet_document.dart';
import '../../documents/screens/edit_document_screen.dart';
import '../../documents/screens/central_document_list_screen.dart';
import '../../documents/services/document_service.dart';

import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
import '../widgets/central_vehicle_assignments_section.dart';
import 'central_vehicle_history_screen.dart';
import 'edit_vehicle_screen.dart';

class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({
    super.key,
    required this.vehicle,
    this.vehicleService,
  });

  final Vehicle vehicle;
  final VehicleService? vehicleService;

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  late Vehicle _vehicle;

  final AssignmentRepository _repository = AssignmentRepository.instance;
  late final VehicleService _vehicleService;
  final DocumentService _documentService = DocumentService();

  final PermissionService _permissions = PermissionService.instance;

  Driver? _assignedDriver;
  late Future<List<FleetDocument>> _documentsFuture;

  @override
  void initState() {
    super.initState();
    _vehicleService =
        widget.vehicleService ?? VehicleService.forConfiguredBackend();
    _vehicle = widget.vehicle;
    if (_isLocalVehicle) {
      _loadAssignedDriver();
      _loadDocuments();
    } else {
      _documentsFuture = Future.value(const <FleetDocument>[]);
    }
  }

  bool get _isLocalVehicle => _vehicle.identity?.localIdOrNull != null;

  void _loadDocuments() {
    final vehicleId = _vehicle.id;
    _documentsFuture = vehicleId == null
        ? Future.value(const <FleetDocument>[])
        : _documentService.getByVehicle(vehicleId);
  }

  Future<void> _addDocument({DocumentCategory? initialCategory}) async {
    final vehicleId = _vehicle.id;
    if (vehicleId == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditDocumentScreen(
          initialVehicleId: vehicleId,
          initialCategory: initialCategory,
        ),
      ),
    );
    if (saved == true && mounted) {
      setState(_loadDocuments);
    }
  }

  Future<void> _editDocument(FleetDocument document) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditDocumentScreen(document: document)),
    );
    if (saved == true && mounted) {
      setState(_loadDocuments);
    }
  }

  Future<void> _loadAssignedDriver() async {
    if (_vehicle.id == null) return;

    final driver = await _repository.getAssignedDriver(_vehicle.id!);

    if (!mounted) return;

    setState(() {
      _assignedDriver = driver;
    });
  }

  Future<void> _assignDriver() async {
    if (_vehicle.id == null) return;

    final driver = await Navigator.push<Driver>(
      context,
      MaterialPageRoute(builder: (_) => const AssignDriverScreen()),
    );

    if (!mounted || driver == null) return;

    await _repository.assignDriver(
      driverId: driver.id!,
      vehicleId: _vehicle.id!,
    );

    await _loadAssignedDriver();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${driver.fullName} assigned successfully.')),
    );
  }

  Future<void> _endAssignment() async {
    if (_vehicle.id == null) return;

    await _repository.unassignVehicle(_vehicle.id!);

    await _loadAssignedDriver();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Driver assignment ended.')));
  }

  Future<void> _refreshVehicle() async {
    final identity = _vehicle.identity;
    if (identity == null) {
      return;
    }

    final vehicle = await _vehicleService.getVehicle(identity);
    if (vehicle == null) {
      throw StateError('Vehicle could not be reloaded.');
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _vehicle = vehicle;
    });
    if (_isLocalVehicle) {
      await _loadAssignedDriver();
    }
  }

  Future<void> _deactivateVehicle() async {
    final identity = _vehicle.identity;
    if (identity == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Vehicle?'),
        content: const Text(
          'This will mark the vehicle as inactive and end any current driver '
          'assignment. Vehicle history and records will be retained.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    try {
      await _vehicleService.deactivateVehicleByIdentity(identity);
      await _refreshVehicle();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vehicle deactivated.')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to deactivate vehicle.')),
      );
    }
  }

  Future<void> _reactivateVehicle() async {
    final identity = _vehicle.identity;
    if (identity == null) {
      return;
    }

    try {
      await _vehicleService.reactivateVehicleByIdentity(identity);
      await _refreshVehicle();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vehicle reactivated.')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to reactivate vehicle.')),
      );
    }
  }

  Widget _detailTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Not Set';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _documentsSection(BuildContext context) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<List<FleetDocument>>(
        future: _documentsFuture,
        builder: (context, snapshot) {
          final documents = snapshot.data ?? const <FleetDocument>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Documents',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  if (_permissions.canManageVehicles)
                    TextButton.icon(
                      onPressed: _addDocument,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Document'),
                    ),
                ],
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snapshot.hasError)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Unable to load linked documents.'),
                )
              else if (documents.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('No documents linked to this vehicle.'),
                )
              else
                ...documents.map(
                  (document) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description_outlined),
                    title: Text(document.title),
                    subtitle: Text(
                      '${document.category.name} â€¢ ${_documentService.status(document.expiryDate)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'View attachment',
                          icon: const Icon(Icons.visibility_outlined),
                          onPressed: document.filePath.isEmpty
                              ? null
                              : () async {
                                  final file = File(document.filePath);
                                  if (!await file.exists()) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Attached file not found.',
                                          ),
                                        ),
                                      );
                                    }
                                    return;
                                  }
                                  await OpenFilex.open(file.path);
                                },
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => _editDocument(document),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (!_permissions.canViewVehicles) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text(
            'You do not have permission to view this vehicle.',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return AppPageScaffold(
      title: 'Vehicle Details',
      subtitle: _vehicle.fleetNumber.trim().isEmpty
          ? _vehicle.registration
          : '${_vehicle.registration} • ${_vehicle.fleetNumber}',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.local_shipping,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _vehicle.registration,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    _vehicle.fleetNumber.trim().isEmpty
                        ? 'Fleet number not recorded'
                        : _vehicle.fleetNumber,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _vehicle.active
                      ? StatusBadge.success('Active')
                      : StatusBadge.neutral('Inactive'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          _detailTile(
            icon: Icons.directions_car,
            title: 'Make',
            value: _vehicle.make,
          ),

          _detailTile(icon: Icons.badge, title: 'Model', value: _vehicle.model),

          _detailTile(
            icon: Icons.calendar_today,
            title: 'Year',
            value: _vehicle.year.toString(),
          ),

          _detailTile(
            icon: Icons.confirmation_number,
            title: 'VIN',
            value: _vehicle.vin,
          ),

          _detailTile(
            icon: Icons.assignment,
            title: 'MOT Expiry',
            value: _formatDate(_vehicle.motExpiry),
          ),

          _detailTile(
            icon: Icons.build,
            title: 'Service Due',
            value: _formatDate(_vehicle.serviceDue),
          ),

          if (_vehicle.taxiPlateNumber?.trim().isNotEmpty == true) ...[
            _detailTile(
              icon: Icons.local_taxi_outlined,
              title: 'Taxi Plate / Licence Number',
              value: _vehicle.taxiPlateNumber!,
            ),
            if (_vehicle.taxiLicensingAuthority?.trim().isNotEmpty == true)
              _detailTile(
                icon: Icons.account_balance_outlined,
                title: 'Licensing Authority',
                value: _vehicle.taxiLicensingAuthority!,
              ),
            _detailTile(
              icon: Icons.event_outlined,
              title: 'Taxi Plate Issue Date',
              value: _formatDate(_vehicle.taxiPlateIssueDate),
            ),
            _detailTile(
              icon: Icons.event_available_outlined,
              title: 'Taxi Plate Expiry',
              value: _formatDate(_vehicle.taxiPlateExpiry),
            ),
            _detailTile(
              icon: Icons.verified_outlined,
              title: 'Taxi Plate Status',
              value: _documentService.status(_vehicle.taxiPlateExpiry),
            ),
            if (_isLocalVehicle && _permissions.canManageVehicles)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _addDocument(initialCategory: DocumentCategory.taxiPlate),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Add Taxi Plate Evidence'),
                ),
              ),
          ],

          const SizedBox(height: 24),

          if (_isLocalVehicle)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver Assignment',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),

                    const SizedBox(height: 16),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(
                        _assignedDriver?.fullName ?? 'No Driver Assigned',
                      ),
                      subtitle: Text(
                        _assignedDriver == null
                            ? 'Select a driver'
                            : 'Currently assigned',
                      ),
                    ),

                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (_permissions.canManageVehicles && _vehicle.active)
                          FilledButton.icon(
                            onPressed: _assignDriver,
                            icon: const Icon(Icons.person_add),
                            label: Text(
                              _assignedDriver == null
                                  ? 'Assign Driver'
                                  : 'Change Driver',
                            ),
                          ),

                        if (_permissions.canManageVehicles &&
                            _assignedDriver != null) ...[
                          OutlinedButton.icon(
                            onPressed: _endAssignment,
                            icon: const Icon(Icons.link_off),
                            label: const Text('End Assignment'),
                          ),
                        ],
                      ],
                    ),
                    if (!_vehicle.active) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Inactive vehicles cannot receive new driver assignments.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          if (_isLocalVehicle) _documentsSection(context),

          if (!_isLocalVehicle && _vehicle.identity != null) ...[
            CentralVehicleAssignmentsSection(
              vehicleIdentity: _vehicle.identity!,
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Related records',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.folder_shared_outlined),
                    title: const Text('Vehicle Documents'),
                    subtitle: const Text(
                      'Upload and view central documents linked to fleet vehicles.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CentralDocumentListScreen(
                          initialFilter: 'Vehicle',
                          entityType: 'vehicle',
                          entityId: _vehicle.identity!.centralIdOrNull,
                          ownerLabel: _vehicle.registration,
                        ),
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history_outlined),
                    title: const Text('Maintenance & Workshop History'),
                    subtitle: const Text(
                      'View central inspections, scheduled-service activity and repair jobs.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => CentralVehicleHistoryScreen(
                          vehicleId: _vehicle.identity!.centralIdOrNull!,
                          registration: _vehicle.registration,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          if (_permissions.canManageVehicles)
            FilledButton.icon(
              onPressed: () async {
                final updatedVehicle = await Navigator.push<Vehicle>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditVehicleScreen(
                      vehicle: _vehicle,
                      vehicleService: _vehicleService,
                    ),
                  ),
                );

                if (!mounted || updatedVehicle == null) {
                  return;
                }

                setState(() {
                  _vehicle = updatedVehicle;
                });

                if (_isLocalVehicle) {
                  await _loadAssignedDriver();
                }
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Vehicle'),
            ),

          if (_permissions.canManageVehicles) const SizedBox(height: 12),

          if (_permissions.canManageVehicles)
            OutlinedButton.icon(
              onPressed: _vehicle.active
                  ? _deactivateVehicle
                  : _reactivateVehicle,
              icon: Icon(
                _vehicle.active
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
              ),
              label: Text(
                _vehicle.active ? 'Deactivate Vehicle' : 'Reactivate Vehicle',
              ),
            ),

          if (_permissions.canManageVehicles) const SizedBox(height: 12),

          if (_isLocalVehicle)
            OutlinedButton.icon(
              onPressed: () async {
                if (_vehicle.id == null) {
                  return;
                }

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AssignmentHistoryScreen(vehicleId: _vehicle.id!),
                  ),
                );

                await _loadAssignedDriver();
              },
              icon: const Icon(Icons.history),
              label: const Text('Assignment History'),
            ),
        ],
      ),
    );
  }
}
