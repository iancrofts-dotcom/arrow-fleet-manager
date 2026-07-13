import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../widgets/driver_form.dart';

class EditDriverScreen extends StatelessWidget {
  final Driver driver;

  const EditDriverScreen({
    super.key,
    required this.driver,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Driver'),
      ),
      body: DriverForm(
        driver: driver,
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