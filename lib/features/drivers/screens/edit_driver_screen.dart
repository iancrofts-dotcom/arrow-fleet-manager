import 'package:flutter/material.dart';

import '../../../backend/drivers/central_driver_management_repository.dart';
import '../../../backend/drivers/supabase_driver_management_gateway.dart';
import '../../../config/backend_mode.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../auth/services/permission_service.dart';
import '../models/driver.dart';
import '../services/driver_service.dart';
import '../widgets/driver_form.dart';

class EditDriverScreen extends StatefulWidget {
  const EditDriverScreen({super.key, required this.driver});

  final Driver driver;

  @override
  State<EditDriverScreen> createState() => _EditDriverScreenState();
}

class _EditDriverScreenState extends State<EditDriverScreen> {
  final PermissionService _permissions = PermissionService.instance;
  final DriverService _localDriverService = DriverService();
  final CentralDriverManagementRepository _centralRepository =
      const CentralDriverManagementRepository(
        SupabaseDriverManagementGateway(),
      );

  bool _saving = false;
  bool get _isCentral => BackendModeConfig.current == BackendMode.supabase;

  Future<void> _saveDriver(Driver updatedDriver) async {
    if (_saving) return;
    final driverToSave = _isCentral
        ? updatedDriver.copyWith(identity: widget.driver.identity)
        : updatedDriver.copyWith(id: widget.driver.id);
    setState(() => _saving = true);

    try {
      final saved = _isCentral
          ? await _centralRepository.updateDriver(driverToSave)
          : await _saveLocal(driverToSave);
      if (!mounted) return;
      Navigator.pop(context, saved);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update driver.\n$error')),
      );
      setState(() => _saving = false);
    }
  }

  Future<Driver> _saveLocal(Driver driver) async {
    await _localDriverService.updateDriver(driver);
    return driver;
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissions.canManageDrivers) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text(
            'You do not have permission to edit drivers.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return AppPageScaffold(
      title: 'Edit Driver',
      subtitle: _isCentral
          ? 'Update the central Driver profile and portal login.'
          : 'Update the existing driver profile.',
      child: Stack(
        children: [
          IgnorePointer(
            ignoring: _saving,
            child: DriverForm(
              driver: widget.driver,
              onSubmit: (driver, _) => _saveDriver(driver),
              submitLabel: 'Update Driver',
              requireEmail: _isCentral,
            ),
          ),
          if (_saving)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
