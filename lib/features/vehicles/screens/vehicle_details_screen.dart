import 'package:flutter/material.dart';

import '../../drivers/models/driver.dart';
import '../../drivers/screens/assign_driver_screen.dart';
import '../../drivers/screens/assignment_history_screen.dart';

import '../../assignments/repositories/assignment_repository.dart';

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

  final AssignmentRepository _repository =
      AssignmentRepository.instance;

  Driver? _assignedDriver;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
    _loadAssignedDriver();
  }

  Future<void> _loadAssignedDriver() async {
    if (_vehicle.id == null) return;

    final driver =
        await _repository.getAssignedDriver(
      _vehicle.id!,
    );

    if (!mounted) return;

    setState(() {
      _assignedDriver = driver;
    });
  }

  Future<void> _assignDriver() async {
    if (_vehicle.id == null) return;

    final driver = await Navigator.push<Driver>(
      context,
      MaterialPageRoute(
        builder: (_) => const AssignDriverScreen(),
      ),
    );

    if (!mounted || driver == null) return;

    await _repository.assignDriver(
      driverId: driver.id!,
      vehicleId: _vehicle.id!,
    );

    await _loadAssignedDriver();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${driver.fullName} assigned successfully.',
        ),
      ),
    );
  }

  Future<void> _endAssignment() async {
    if (_vehicle.id == null) return;

    await _repository.unassignVehicle(
      _vehicle.id!,
    );

    await _loadAssignedDriver();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Driver assignment ended.',
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

          const SizedBox(height: 24),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Driver Assignment',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge,
                  ),

                  const SizedBox(height: 16),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(
                      _assignedDriver?.fullName ??
                          'No Driver Assigned',
                    ),
                    subtitle: Text(
                      _assignedDriver == null
                          ? 'Select a driver'
                          : 'Currently assigned',
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _assignDriver,
                          icon: const Icon(
                            Icons.person_add,
                          ),
                          label: Text(
                            _assignedDriver == null
                                ? 'Assign Driver'
                                : 'Change Driver',
                          ),
                        ),
                      ),

                      if (_assignedDriver != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _endAssignment,
                            icon: const Icon(Icons.link_off),
                            label: const Text(
                              'End Assignment',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: () async {
              final updatedVehicle =
                  await Navigator.push<Vehicle>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EditVehicleScreen(
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
            label: const Text(
              'Edit Vehicle',
            ),
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