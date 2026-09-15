import 'package:flutter/material.dart';

import '../../documents/screens/central_document_list_screen.dart';

import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
import '../widgets/central_vehicle_assignments_section.dart';
import 'central_vehicle_history_screen.dart';
import 'edit_vehicle_screen.dart';

class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({
    super.key,
    required this.vehicle,
    required this.vehicleService,
  });

  final Vehicle vehicle;
  final VehicleService vehicleService;

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  late Vehicle _vehicle = widget.vehicle;

  Future<void> _edit() async {
    final updated = await Navigator.push<Vehicle>(
      context,
      MaterialPageRoute(
        builder: (_) => EditVehicleScreen(
          vehicle: _vehicle,
          vehicleService: widget.vehicleService,
        ),
      ),
    );
    if (updated != null && mounted) setState(() => _vehicle = updated);
  }

  Future<void> _setActive(bool active) async {
    final identity = _vehicle.identity;
    if (identity == null) return;
    final updated = active
        ? await widget.vehicleService.reactivateVehicleByIdentity(identity)
        : await widget.vehicleService.deactivateVehicleByIdentity(identity);
    if (mounted) setState(() => _vehicle = updated);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_vehicle.registration),
      actions: [IconButton(onPressed: _edit, icon: const Icon(Icons.edit))],
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ListTile(
          title: const Text('Fleet number'),
          subtitle: Text(
            _vehicle.fleetNumber.trim().isEmpty
                ? 'Not recorded'
                : _vehicle.fleetNumber,
          ),
        ),
        ListTile(title: const Text('Make'), subtitle: Text(_vehicle.make)),
        ListTile(title: const Text('Model'), subtitle: Text(_vehicle.model)),
        ListTile(title: const Text('Year'), subtitle: Text('${_vehicle.year}')),
        SwitchListTile(
          title: const Text('Active'),
          value: _vehicle.active,
          onChanged: _setActive,
        ),
        if (_vehicle.identity?.centralIdOrNull case final centralId?) ...[
          const SizedBox(height: 24),
          CentralVehicleAssignmentsSection(
            vehicleIdentity: _vehicle.identity!,
            key: ValueKey('central-vehicle-assignments-$centralId'),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_shared_outlined),
                  title: const Text('Vehicle Documents'),
                  subtitle: const Text(
                    'View and manage central documents linked to this Vehicle.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => CentralDocumentListScreen(
                        initialFilter: 'Vehicle',
                        entityType: 'vehicle',
                        entityId: centralId,
                        ownerLabel: _vehicle.registration,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history_outlined),
                  title: const Text('Maintenance & Workshop History'),
                  subtitle: const Text(
                    'View central inspections, scheduled-service activity and repair jobs.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => CentralVehicleHistoryScreen(
                        vehicleId: centralId,
                        registration: _vehicle.registration,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
