import 'package:flutter/material.dart';

import '../../auth/services/permission_service.dart';

import '../models/driver.dart';
import '../services/driver_service.dart';
import '../widgets/driver_card.dart';
import 'add_driver_screen.dart';
import 'driver_details_screen.dart';

class DriverListScreen extends StatefulWidget {
  const DriverListScreen({super.key});

  @override
  State<DriverListScreen> createState() =>
      _DriverListScreenState();
}

class _DriverListScreenState
    extends State<DriverListScreen> {
  final DriverService _driverService =
      DriverService();

  final PermissionService _permissions =
      PermissionService.instance;

  late Future<List<Driver>> _driversFuture;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  void _loadDrivers() {
    _driversFuture = _driverService.getDrivers();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadDrivers();
    });

    await _driversFuture;
  }

  Future<void> _addDriver() async {
    final driver =
        await Navigator.push<Driver>(
      context,
      MaterialPageRoute(
        builder: (_) => AddDriverScreen(),
      ),
    );

    if (driver == null) return;

    if (!mounted) return;

    setState(_loadDrivers);

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '${driver.fullName} added successfully.',
        ),
      ),
    );
  }

  Future<void> _openDriver(
    Driver driver,
  ) async {
    final refresh =
        await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DriverDetailsScreen(
          driver: driver,
        ),
      ),
    );

    if (refresh == true && mounted) {
      setState(_loadDrivers);
    }
  }

  Future<void> _deleteDriver(
    Driver driver,
  ) async {
    if (driver.id == null) return;

    final confirm =
        await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Delete Driver',
        ),
        content: Text(
          'Delete ${driver.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
              context,
              false,
            ),
            child:
                const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(
              context,
              true,
            ),
            child:
                const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _driverService.deleteDriver(
      driver.id!,
    );

    if (!mounted) return;

    setState(_loadDrivers);

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '${driver.fullName} deleted.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissions.canViewDrivers) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Access Denied',
          ),
        ),
        body: const Center(
          child: Text(
            'You do not have permission to view drivers.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Drivers',
        ),
      ),
      floatingActionButton:
          _permissions.canManageDrivers
              ? FloatingActionButton.extended(
                  onPressed: _addDriver,
                  icon: const Icon(
                    Icons.add,
                  ),
                  label: const Text(
                    'Add Driver',
                  ),
                )
              : null,
      body: FutureBuilder<List<Driver>>(
        future: _driversFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
              ),
            );
          }

          final drivers =
              snapshot.data ??
                  const <Driver>[];

          if (drivers.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 150),
                  Center(
                    child: Text(
                      'No drivers found.\nTap Add Driver to begin.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: drivers.length,
              itemBuilder:
                  (context, index) {
                final driver =
                    drivers[index];

                if (_permissions
                    .canManageDrivers) {
                  return Dismissible(
                    key: ValueKey(
                      driver.id,
                    ),
                    direction:
                        DismissDirection
                            .endToStart,
                    background:
                        Container(
                      color: Colors.red,
                      alignment:
                          Alignment
                              .centerRight,
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 20,
                      ),
                      child: const Icon(
                        Icons.delete,
                        color:
                            Colors.white,
                      ),
                    ),
                    confirmDismiss:
                        (_) async {
                      await _deleteDriver(
                        driver,
                      );
                      return false;
                    },
                    child: DriverCard(
                      driver: driver,
                      onTap: () =>
                          _openDriver(
                        driver,
                      ),
                    ),
                  );
                }

                return DriverCard(
                  driver: driver,
                  onTap: () =>
                      _openDriver(
                    driver,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}