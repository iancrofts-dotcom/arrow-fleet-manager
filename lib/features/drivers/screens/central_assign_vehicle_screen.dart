import 'package:flutter/material.dart';

import '../../../backend/drivers/central_driver_assignment_write_service.dart';
import '../../../backend/vehicles/backend_vehicle.dart';
import '../../../backend/vehicles/backend_vehicle_repository.dart';
import '../../../backend/vehicles/supabase_vehicle_gateway.dart';
import '../../../shared/widgets/app_page_scaffold.dart';

class CentralAssignVehicleScreen extends StatefulWidget {
  const CentralAssignVehicleScreen({
    super.key,
    required this.driverId,
    required this.driverName,
    this.writeService,
  });

  final String driverId;
  final String driverName;
  final CentralDriverAssignmentWriteService? writeService;

  @override
  State<CentralAssignVehicleScreen> createState() =>
      _CentralAssignVehicleScreenState();
}

class _CentralAssignVehicleScreenState
    extends State<CentralAssignVehicleScreen> {
  late final CentralDriverAssignmentWriteService _writeService;
  final _vehicles = BackendVehicleRepository(SupabaseVehicleGateway());
  late Future<List<BackendVehicle>> _future;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _writeService =
        widget.writeService ?? CentralDriverAssignmentWriteService();
    _future = _vehicles.listVehicles();
  }

  Future<void> _assign(BackendVehicle vehicle) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _writeService.assign(
        driverId: widget.driverId,
        vehicleId: vehicle.id,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to assign Vehicle: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    title: 'Assign Vehicle',
    subtitle: 'Select a Vehicle for ${widget.driverName}.',
    child: FutureBuilder<List<BackendVehicle>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingState(label: 'Loading Vehicles...');
        }
        if (snapshot.hasError) {
          return AppErrorState(
            title: 'Unable to load Vehicles',
            message: '${snapshot.error}',
            onRetry: () => setState(() => _future = _vehicles.listVehicles()),
          );
        }
        final vehicles = (snapshot.data ?? const <BackendVehicle>[])
            .where((vehicle) => vehicle.isActive)
            .toList(growable: false);
        if (vehicles.isEmpty) {
          return const AppEmptyState(
            icon: Icons.local_shipping_outlined,
            title: 'No active Vehicles',
            message: 'Add or reactivate a Vehicle before assigning a Driver.',
          );
        }
        return ListView.separated(
          itemCount: vehicles.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final vehicle = vehicles[index];
            return ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.local_shipping_outlined),
              ),
              title: Text(vehicle.registration),
              subtitle: Text(
                '${vehicle.fleetNumber} · ${vehicle.make ?? ''} ${vehicle.model ?? ''}'
                    .trim(),
              ),
              trailing: _saving ? null : const Icon(Icons.chevron_right),
              enabled: !_saving,
              onTap: () => _assign(vehicle),
            );
          },
        );
      },
    ),
  );
}
