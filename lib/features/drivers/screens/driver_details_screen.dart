import 'package:flutter/material.dart';
import 'driver_compliance_screen.dart';
import '../models/driver.dart';
import 'edit_driver_screen.dart';
import '../../vehicles/models/vehicle.dart';
import '../../assignments/repositories/assignment_repository.dart';
import '../../vehicles/screens/assign_vehicle_screen.dart';

class DriverDetailsScreen extends StatefulWidget {
  const DriverDetailsScreen({
    super.key,
    required this.driver,
  });

  final Driver driver;

  @override
  State<DriverDetailsScreen> createState() =>
      _DriverDetailsScreenState();
}

class _DriverDetailsScreenState
    extends State<DriverDetailsScreen> {

  final AssignmentRepository _repository =
    AssignmentRepository.instance;

  Vehicle? _assignedVehicle;

  bool _loadingVehicle = true;

  @override
  void initState() {
    super.initState();
    _loadAssignedVehicle();
  }

  Future<void> _loadAssignedVehicle() async {
    if (widget.driver.id == null) {
      setState(() {
        _loadingVehicle = false;
      });
      return;
    }

    final vehicle =
        await _repository.getAssignedVehicle(
      widget.driver.id!,
    );

    if (!mounted) return;

    setState(() {
      _assignedVehicle = vehicle;
      _loadingVehicle = false;
    });
  }

Future<void> _assignVehicle() async {
  if (widget.driver.id == null) return;

  final vehicle = await Navigator.push<Vehicle>(
    context,
    MaterialPageRoute(
      builder: (_) => const AssignVehicleScreen(),
    ),
  );

  if (!mounted || vehicle == null || vehicle.id == null) {
    return;
  }

  await _repository.assignDriver(
    driverId: widget.driver.id!,
    vehicleId: vehicle.id!,
  );

  await _loadAssignedVehicle();

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '${vehicle.registration} assigned successfully.',
      ),
    ),
  );
}

Future<void> _endAssignment() async {
  if (_assignedVehicle?.id == null) return;

  await _repository.unassignVehicle(
    _assignedVehicle!.id!,
  );

  await _loadAssignedVehicle();

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Vehicle assignment ended.',
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final driver = widget.driver;
    return Scaffold(
      appBar: AppBar(
        title: Text(driver.fullName),
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
                  CircleAvatar(
                    radius: 40,
                    child: Text(
                      driver.firstName.substring(0, 1),
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    driver.fullName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    driver.licenceNumber,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

      _detailTile(
  context,
  Icons.phone,
  'Phone',
  driver.phone ?? 'Not provided',
),

_detailTile(
  context,
  Icons.email,
  'Email',
  driver.email ?? 'Not provided',
),

          _detailTile(
            context,
            Icons.badge,
            'Licence Number',
            driver.licenceNumber,
          ),

          _detailTile(
            context,
            Icons.calendar_today,
            'Licence Expiry',
            driver.licenceExpiry != null
                ? _formatDate(driver.licenceExpiry!)
                : 'Not set',
          ),
        Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Assignment',
          style: Theme.of(context)
              .textTheme
              .titleLarge,
        ),

        const SizedBox(height: 16),

        if (_loadingVehicle)
          const Center(
            child: CircularProgressIndicator(),
          )
        else
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.local_shipping,
            ),
            title: Text(
              _assignedVehicle?.registration ??
                  'No Vehicle Assigned',
            ),
            subtitle: Text(
              _assignedVehicle == null
                  ? 'Select a vehicle'
                  : '${_assignedVehicle!.fleetNumber}\n'
                      '${_assignedVehicle!.make} ${_assignedVehicle!.model}',
            ),
            isThreeLine:
                _assignedVehicle != null,
          ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _assignVehicle,
                icon: const Icon(
                  Icons.local_shipping,
                ),
                label: Text(
                  _assignedVehicle == null
                      ? 'Assign Vehicle'
                      : 'Change Vehicle',
                ),
              ),
            ),

            if (_assignedVehicle != null) ...[
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
          const SizedBox(height: 24),

         Card(
  child: ListTile(
    leading: const Icon(Icons.verified_user),
    title: const Text('Driver Compliance'),
    subtitle: const Text(
      'View and manage licence, CPC and medical expiry dates.',
    ),
    trailing: const Icon(Icons.chevron_right),
    onTap: () async {
      if (driver.id == null) {
        return;
      }

      final refresh = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => DriverComplianceScreen(
            driverId: driver.id!,
          ),
        ),
      );

      if (refresh == true && mounted) {
        setState(() {
          _loadAssignedVehicle();
        });
      }
    },
  ),
),

          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditDriverScreen(
                    driver: driver,
                  ),
                ),
              );

              if (context.mounted) {
                Navigator.pop(context, true);
              }
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Driver'),
          ),
        ],
      ),
    );
  }

  Widget _detailTile(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}