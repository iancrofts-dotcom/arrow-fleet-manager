import 'package:flutter/material.dart';

import '../../auth/services/permission_service.dart';

import '../models/driver.dart';
import '../services/driver_service.dart';
import '../widgets/driver_form.dart';

class AddDriverScreen extends StatefulWidget {
  const AddDriverScreen({
    super.key,
  });

  @override
  State<AddDriverScreen> createState() =>
      _AddDriverScreenState();
}

class _AddDriverScreenState
    extends State<AddDriverScreen> {

  final PermissionService _permissions =
      PermissionService.instance;

  final DriverService _driverService =
      DriverService();

  bool _saving = false;

  Future<void> _saveDriver(
    Driver driver,
  ) async {

    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {

      final savedDriver =
          await _driverService.addDriver(
        driver,
      );

      if (!mounted) return;

      Navigator.pop(
        context,
        savedDriver,
      );

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save driver.\n$e',
          ),
        ),
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
        appBar: AppBar(
          title: const Text(
            'Access Denied',
          ),
        ),
        body: const Center(
          child: Text(
            'You do not have permission to add drivers.',
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
          'Add Driver',
        ),
      ),
      body: IgnorePointer(
        ignoring: _saving,
        child: DriverForm(
          onSubmit: _saveDriver,
                  ),
      ),
    );
  }
}