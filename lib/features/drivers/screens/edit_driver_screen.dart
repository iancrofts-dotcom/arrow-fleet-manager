import 'package:flutter/material.dart';

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
  final DriverService _driverService = DriverService();

  bool _saving = false;

  Future<void> _saveDriver(Driver updatedDriver) async {
    if (_saving) return;

    final driverToSave = updatedDriver.copyWith(id: widget.driver.id);

    setState(() {
      _saving = true;
    });

    try {
      await _driverService.updateDriver(driverToSave);

      if (!mounted) return;

      Navigator.pop(context, driverToSave);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update driver.\n$error')),
      );
      setState(() {
        _saving = false;
      });
    }
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

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Driver')),
      body: Stack(
        children: [
          IgnorePointer(
            ignoring: _saving,
            child: DriverForm(
              driver: widget.driver,
              onSubmit: (driver, _) => _saveDriver(driver),
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
