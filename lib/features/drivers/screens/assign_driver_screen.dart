import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../services/driver_service.dart';
import '../../../shared/status_badge.dart';
import '../../../shared/widgets/app_page_scaffold.dart';

class AssignDriverScreen extends StatefulWidget {
  const AssignDriverScreen({super.key});

  @override
  State<AssignDriverScreen> createState() => _AssignDriverScreenState();
}

class _AssignDriverScreenState extends State<AssignDriverScreen> {
  final DriverService _driverService = DriverService();

  bool _loading = true;

  List<Driver> _drivers = [];

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    final drivers = (await _driverService.getDrivers())
        .where((driver) => driver.isActive)
        .toList(growable: false);

    if (!mounted) return;

    setState(() {
      _drivers = drivers;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Assign Driver',
      subtitle: 'Select an active driver for this vehicle.',
      child: _loading
          ? const AppLoadingState(label: 'Loading active drivers...')
          : _drivers.isEmpty
          ? const AppEmptyState(
              icon: Icons.people_outline,
              title: 'No active drivers available',
              message: 'Only active drivers can be assigned to a vehicle.',
            )
          : ListView.builder(
              itemCount: _drivers.length,
              itemBuilder: (context, index) {
                final driver = _drivers[index];

                return Card(
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: const Icon(Icons.person_outline),
                    title: Text(driver.fullName),
                    subtitle: Text('Licence: ${driver.licenceNumber}'),
                    trailing: StatusBadge.success('Active'),
                    onTap: () => Navigator.pop(context, driver),
                  ),
                );
              },
            ),
    );
  }
}
