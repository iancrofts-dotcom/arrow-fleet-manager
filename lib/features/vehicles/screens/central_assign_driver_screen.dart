import 'package:flutter/material.dart';

import '../../../backend/drivers/backend_driver.dart';
import '../../../backend/drivers/backend_driver_repository.dart';
import '../../../backend/drivers/central_driver_assignment_write_service.dart';
import '../../../backend/drivers/supabase_driver_gateway.dart';
import '../../../shared/widgets/app_page_scaffold.dart';

class CentralAssignDriverScreen extends StatefulWidget {
  const CentralAssignDriverScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleLabel,
    this.writeService,
  });

  final String vehicleId;
  final String vehicleLabel;
  final CentralDriverAssignmentWriteService? writeService;

  @override
  State<CentralAssignDriverScreen> createState() =>
      _CentralAssignDriverScreenState();
}

class _CentralAssignDriverScreenState extends State<CentralAssignDriverScreen> {
  final _drivers = BackendDriverRepository(SupabaseDriverGateway());
  late final CentralDriverAssignmentWriteService _writeService;
  late Future<List<BackendDriver>> _future;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _writeService =
        widget.writeService ?? CentralDriverAssignmentWriteService();
    _future = _drivers.listDrivers();
  }

  Future<void> _assign(BackendDriver driver) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _writeService.assign(
        driverId: driver.id,
        vehicleId: widget.vehicleId,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to assign Driver: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    title: 'Assign Driver',
    subtitle: 'Select a Driver for ${widget.vehicleLabel}.',
    child: FutureBuilder<List<BackendDriver>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingState(label: 'Loading Drivers...');
        }
        if (snapshot.hasError) {
          return AppErrorState(
            title: 'Unable to load Drivers',
            message: '${snapshot.error}',
            onRetry: () => setState(() => _future = _drivers.listDrivers()),
          );
        }
        final drivers = (snapshot.data ?? const <BackendDriver>[])
            .where((driver) => driver.isActive)
            .toList(growable: false);
        if (drivers.isEmpty) {
          return const AppEmptyState(
            icon: Icons.person_off_outlined,
            title: 'No active Drivers',
            message: 'Add or reactivate a Driver before assigning a Vehicle.',
          );
        }
        return ListView.separated(
          itemCount: drivers.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final driver = drivers[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text('${driver.firstName} ${driver.lastName}'.trim()),
              subtitle: Text(driver.licenceNumber),
              trailing: _saving ? null : const Icon(Icons.chevron_right),
              enabled: !_saving,
              onTap: () => _assign(driver),
            );
          },
        );
      },
    ),
  );
}
