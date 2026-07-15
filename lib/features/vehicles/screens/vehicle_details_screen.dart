import 'package:flutter/material.dart';

import '../../drivers/models/driver.dart';

import '../../drivers/screens/assign_driver_screen.dart';
import '../../drivers/screens/assignment_history_screen.dart';
import '../../drivers/services/driver_assignment_service.dart';
import '../models/vehicle.dart';
import 'edit_vehicle_screen.dart';

class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({
    super.key,
    required this.vehicle,
  });

  final Vehicle vehicle;

  @override
  State<VehicleDetailsScreen> createState() =>
      _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState
    extends State<VehicleDetailsScreen> {
  late Vehicle _vehicle;

  final DriverAssignmentService _assignmentService =
      DriverAssignmentService();

  
  Driver? _assignedDriver;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
    _loadAssignedDriver();
  }

  Future<void> _loadAssignedDriver() async {
    if (_vehicle.id == null) {
      return;
    }

    try {
      final driver =
          await _assignmentService.getAssignedDriver(
        _vehicle.id!,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _assignedDriver = driver;
      });
    } catch (e, stackTrace) {
      debugPrint(
        'Error loading assigned driver: $e',
      );
      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _assignedDriver = null;
      });
    }
  }

  Future<void> _assignDriver() async {
  if (_vehicle.id == null) {
    return;
  }

  final driver = await Navigator.push<Driver>(
    context,
    MaterialPageRoute(
      builder: (_) => const AssignDriverScreen(),
    ),
  );

  if (!mounted || driver == null) {
    return;
  }

  // End the current assignment (if there is one).
  await _assignmentService.assignDriverToVehicle(
  vehicleId: _vehicle.id!,
  driver: driver,
);

  await _loadAssignedDriver();

  if (!mounted) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '${driver.fullName} assigned successfully.',
      ),
    ),
  );
}
    Widget _detailTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_vehicle.registration),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.local_shipping,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _vehicle.registration,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall,
                  ),
                  Text(
                    _vehicle.fleetNumber,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
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

          _detailTile(
            icon: Icons.badge,
            title: 'Model',
            value: _vehicle.model,
          ),

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

          const SizedBox(height: 20),

          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Assigned Driver'),
              subtitle: Text(
                _assignedDriver?.fullName ??
                    'No driver assigned',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.person_add),
                tooltip: 'Assign Driver',
                onPressed: _assignDriver,
              ),
            ),
          ),

          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: () async {
              final updatedVehicle =
                  await Navigator.push<Vehicle>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditVehicleScreen(
                    vehicle: _vehicle,
                  ),
                ),
              );

              if (!mounted ||
                  updatedVehicle == null) {
                return;
              }

              setState(() {
                _vehicle = updatedVehicle;
              });

              await _loadAssignedDriver();
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Vehicle'),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () async {
              if (_vehicle.id == null) {
                return;
              }

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AssignmentHistoryScreen(
                    vehicleId: _vehicle.id!,
                  ),
                ),
              );

              if (!mounted) {
                return;
              }

              await _loadAssignedDriver();
            },
            icon: const Icon(Icons.history),
            label: const Text(
              'Assignment History',
            ),
          ),
        ],
      ),
    );
  }
}