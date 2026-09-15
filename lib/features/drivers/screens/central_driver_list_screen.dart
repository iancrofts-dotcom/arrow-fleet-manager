import 'package:flutter/material.dart';

import '../../../shared/widgets/app_page_scaffold.dart';
import '../../auth/services/permission_service.dart';
import '../models/driver.dart';
import '../services/driver_read_service.dart';
import '../widgets/driver_card.dart';
import 'central_driver_details_screen.dart';

class DriverListScreen extends StatefulWidget {
  const DriverListScreen({super.key, this.driverReadService, this.permissions});

  final DriverReadService? driverReadService;
  final PermissionService? permissions;

  @override
  State<DriverListScreen> createState() => _DriverListScreenState();
}

class _DriverListScreenState extends State<DriverListScreen> {
  late final DriverReadService _driverReadService;
  late final PermissionService _permissions;
  late Future<List<Driver>> _driversFuture;

  @override
  void initState() {
    super.initState();
    _driverReadService =
        widget.driverReadService ?? DriverReadService.forConfiguredBackend();
    _permissions = widget.permissions ?? PermissionService.instance;
    _loadDrivers();
  }

  void _loadDrivers() {
    _driversFuture = _driverReadService.getDrivers();
  }

  Future<void> _refresh() async {
    setState(_loadDrivers);
    await _driversFuture;
  }

  Future<void> _openDriver(Driver driver) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CentralDriverDetailsScreen(driver: driver),
      ),
    );
    if (changed == true && mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissions.canViewDrivers) {
      return const Scaffold(
        body: Center(
          child: Text('You do not have permission to view drivers.'),
        ),
      );
    }
    return AppPageScaffold(
      title: 'Drivers',
      subtitle: 'Shared central Driver records (read-only).',
      child: FutureBuilder<List<Driver>>(
        future: _driversFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(label: 'Loading drivers...');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Unable to load drivers',
              message: 'Please try again.',
              onRetry: _refresh,
            );
          }
          final drivers = snapshot.data ?? const <Driver>[];
          if (drivers.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 96),
                  AppEmptyState(
                    icon: Icons.people_outline,
                    title: 'No drivers found',
                    message: 'No central Driver records are available.',
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: drivers.length,
              itemBuilder: (context, index) {
                final driver = drivers[index];
                return DriverCard(
                  key: ValueKey(driver.identity),
                  driver: driver,
                  onTap: () => _openDriver(driver),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
