import 'package:flutter/material.dart';

import '../../../backend/drivers/central_driver_management_repository.dart';
import '../../../backend/drivers/supabase_driver_management_gateway.dart';
import '../../../config/backend_mode.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../auth/services/permission_service.dart';
import '../models/driver.dart';
import '../models/driver_creation_request.dart';
import '../services/driver_service.dart';
import '../widgets/driver_form.dart';

class AddDriverScreen extends StatefulWidget {
  const AddDriverScreen({super.key});

  @override
  State<AddDriverScreen> createState() => _AddDriverScreenState();
}

class _AddDriverScreenState extends State<AddDriverScreen> {
  final PermissionService _permissions = PermissionService.instance;
  final DriverService _localDriverService = DriverService();
  final CentralDriverManagementRepository _centralRepository =
      const CentralDriverManagementRepository(
        SupabaseDriverManagementGateway(),
      );

  bool _saving = false;
  bool get _isCentral => BackendModeConfig.current == BackendMode.supabase;

  Future<void> _saveDriver(Driver driver, String password) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final savedDriver = _isCentral
          ? await _centralRepository.createDriver(driver)
          : await _localDriverService.addDriver(
              DriverCreationRequest(driver: driver, password: password),
            );
      if (!mounted) return;
      Navigator.pop(context, savedDriver);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save driver.\n$error')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissions.canManageDrivers) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text(
            'You do not have permission to add drivers.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return AppPageScaffold(
      title: 'Add Driver',
      subtitle: _isCentral
          ? 'Create a Driver profile and send a secure invitation for them to set their own password.'
          : 'Create a driver profile and portal account.',
      child: IgnorePointer(
        ignoring: _saving,
        child: DriverForm(
          onSubmit: _saveDriver,
          submitLabel: _isCentral
              ? 'Create Driver & Send Invitation'
              : 'Add Driver',
          requireEmail: _isCentral,
          invitationMode: _isCentral,
        ),
      ),
    );
  }
}
