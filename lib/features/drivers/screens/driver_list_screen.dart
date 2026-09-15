import 'package:flutter/material.dart';

import '../../auth/services/permission_service.dart';
import '../../../config/backend_mode.dart';
import '../../../backend/drivers/central_driver_management_repository.dart';
import '../../../backend/drivers/supabase_driver_management_gateway.dart';
import '../../../shared/widgets/app_page_scaffold.dart';

import '../models/driver.dart';
import '../services/driver_read_service.dart';
import '../services/driver_service.dart';
import '../widgets/driver_card.dart';
import 'add_driver_screen.dart';
import 'driver_details_screen.dart';
import 'central_driver_details_screen.dart';

class DriverListScreen extends StatefulWidget {
  const DriverListScreen({
    super.key,
    this.driverReadService,
    this.localDriverService,
    this.permissions,
    this.backendMode,
  });

  final DriverReadService? driverReadService;
  final DriverService? localDriverService;
  final PermissionService? permissions;
  final BackendMode? backendMode;

  @override
  State<DriverListScreen> createState() => _DriverListScreenState();
}

class _DriverListScreenState extends State<DriverListScreen> {
  late final DriverReadService _driverReadService;
  late final DriverService? _localDriverService;
  late final PermissionService _permissions;
  late final BackendMode _backendMode;
  final CentralDriverManagementRepository _centralManagement =
      const CentralDriverManagementRepository(
        SupabaseDriverManagementGateway(),
      );

  bool get _isCentral => _backendMode == BackendMode.supabase;

  late Future<List<Driver>> _driversFuture;

  @override
  void initState() {
    super.initState();
    _backendMode = widget.backendMode ?? BackendModeConfig.current;
    _driverReadService =
        widget.driverReadService ?? DriverReadService.forMode(_backendMode);
    _localDriverService = _isCentral
        ? widget.localDriverService
        : widget.localDriverService ?? DriverService();
    _permissions = widget.permissions ?? PermissionService.instance;
    _loadDrivers();
  }

  void _loadDrivers() {
    _driversFuture = _driverReadService.getDrivers();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadDrivers();
    });

    await _driversFuture;
  }

  Future<void> _addDriver() async {
    final driver = await Navigator.push<Driver>(
      context,
      MaterialPageRoute(builder: (_) => AddDriverScreen()),
    );

    if (driver == null) return;

    if (!mounted) return;

    setState(_loadDrivers);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${driver.fullName} added successfully.')),
    );
  }

  Future<void> _openDriver(Driver driver) async {
    final refresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _isCentral
            ? CentralDriverDetailsScreen(driver: driver)
            : DriverDetailsScreen(driver: driver),
      ),
    );

    if (refresh == true && mounted) {
      setState(_loadDrivers);
    }
  }

  Future<void> _deactivateDriver(Driver driver) async {
    if (!_isCentral && driver.id == null) return;
    if (_isCentral && driver.identity?.centralIdOrNull == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deactivate Driver'),
        content: Text(
          'Deactivate ${driver.fullName}?\n\n'
          'The driver will become inactive. Assignment history and records '
          'will be retained.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (_isCentral) {
        final identity = driver.identity;
        if (identity == null) {
          throw StateError('Central Driver identity is missing.');
        }
        await _centralManagement.deactivateDriver(identity);
      } else {
        await _localDriverService!.deactivateDriver(driver.id!);
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to deactivate driver.\n$error')),
      );
      return;
    }

    if (!mounted) return;

    setState(_loadDrivers);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${driver.fullName} deactivated.')));
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissions.canViewDrivers) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text(
            'You do not have permission to view drivers.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return AppPageScaffold(
      title: 'Drivers',
      subtitle: _isCentral
          ? 'Manage shared central Driver records and portal accounts.'
          : 'Manage driver records and fleet access.',
      floatingActionButton: _permissions.canManageDrivers
          ? FloatingActionButton.extended(
              onPressed: _addDriver,
              icon: const Icon(Icons.add),
              label: const Text('Add Driver'),
            )
          : null,
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
                children: [
                  const SizedBox(height: 96),
                  AppEmptyState(
                    icon: Icons.people_outline,
                    title: 'No drivers found',
                    message: _isCentral
                        ? 'No central Driver records are available.'
                        : 'Use Add Driver to begin building the driver team.',
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

                if (_permissions.canManageDrivers) {
                  return Dismissible(
                    key: ValueKey(driver.identity ?? driver.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Theme.of(context).colorScheme.errorContainer,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Icon(
                        Icons.person_off_outlined,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        semanticLabel: 'Deactivate driver',
                      ),
                    ),
                    confirmDismiss: (_) async {
                      await _deactivateDriver(driver);
                      return false;
                    },
                    child: DriverCard(
                      driver: driver,
                      onTap: () => _openDriver(driver),
                    ),
                  );
                }

                return DriverCard(
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
