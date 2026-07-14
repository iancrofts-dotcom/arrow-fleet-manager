import 'package:flutter/material.dart';

import '../models/vehicle.dart';

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

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
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
              subtitle: const Text('No driver assigned'),
              trailing: IconButton(
                icon: const Icon(Icons.person_add),
                tooltip: 'Assign Driver',
                onPressed: () {
                  // Driver assignment will be added next.
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}