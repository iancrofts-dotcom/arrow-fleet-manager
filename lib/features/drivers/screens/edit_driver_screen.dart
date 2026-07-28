import 'package:flutter/material.dart';

import '../../auth/services/permission_service.dart';

import '../models/driver.dart';
import '../widgets/driver_form.dart';

class EditDriverScreen extends StatelessWidget {
  final Driver driver;

  EditDriverScreen({
    super.key,
    required this.driver,
  });

  final PermissionService _permissions =
      PermissionService.instance;

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
            'You do not have permission to edit drivers.',
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
          'Edit Driver',
        ),
      ),
      body: DriverForm(        driver: driver,
        onSubmit: (updatedDriver) {
          Navigator.pop(
            context,
            updatedDriver,
          );
        },
      ),
    );
  }
}