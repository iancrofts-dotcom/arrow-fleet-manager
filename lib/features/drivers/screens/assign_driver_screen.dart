import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../services/driver_service.dart';

class AssignDriverScreen extends StatefulWidget {
  const AssignDriverScreen({
    super.key,
  });

  @override
  State<AssignDriverScreen> createState() =>
      _AssignDriverScreenState();
}

class _AssignDriverScreenState
    extends State<AssignDriverScreen> {
  final DriverService _driverService =
      DriverService();

  bool _loading = true;

  List<Driver> _drivers = [];

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    final drivers =
        await _driverService.getDrivers();

    if (!mounted) return;

    setState(() {
      _drivers = drivers;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Driver'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _drivers.isEmpty
              ? const Center(
                  child: Text(
                    'No active drivers.',
                  ),
                )
              : ListView.builder(
                  itemCount: _drivers.length,
                  itemBuilder: (context, index) {
                    final driver = _drivers[index];

                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(driver.fullName),
                      subtitle: Text(
                        driver.licenceNumber,
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                      ),
                      onTap: () {
                        Navigator.pop(
                          context,
                          driver,
                        );
                      },
                    );
                  },
                ),
    );
  }
}