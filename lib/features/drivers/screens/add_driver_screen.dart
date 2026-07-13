import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../widgets/driver_form.dart';

class AddDriverScreen extends StatelessWidget {
  const AddDriverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Driver'),
      ),
      body: DriverForm(
        onSubmit: (Driver driver) {
          Navigator.pop(
            context,
            driver,
          );
        },
      ),
    );
  }
}