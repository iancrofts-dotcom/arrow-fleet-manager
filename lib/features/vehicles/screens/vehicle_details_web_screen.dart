import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
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
          subtitle: Text(_vehicle.fleetNumber),
        ),
        ListTile(title: const Text('Make'), subtitle: Text(_vehicle.make)),
        ListTile(title: const Text('Model'), subtitle: Text(_vehicle.model)),
        ListTile(title: const Text('Year'), subtitle: Text('${_vehicle.year}')),
        SwitchListTile(
          title: const Text('Active'),
          value: _vehicle.active,
          onChanged: _setActive,
        ),
        const Padding(
          padding: EdgeInsets.only(top: 24),
          child: Text(
            'Assignments, documents and history are still being migrated to the central backend.',
          ),
        ),
      ],
    ),
  );
}
