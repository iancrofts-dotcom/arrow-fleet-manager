import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../services/driver_service.dart';

class DriverAssignmentPicker extends StatefulWidget {
  const DriverAssignmentPicker({
    super.key,
    this.selectedDriver,
    required this.onChanged,
  });

  final Driver? selectedDriver;
  final ValueChanged<Driver?> onChanged;

  @override
  State<DriverAssignmentPicker> createState() =>
      _DriverAssignmentPickerState();
}

class _DriverAssignmentPickerState
    extends State<DriverAssignmentPicker> {
  final DriverService _driverService =
      DriverService();

  late Future<List<Driver>> _driversFuture;

  Driver? _selectedDriver;

  @override
  void initState() {
    super.initState();

    _selectedDriver = widget.selectedDriver;
    _driversFuture = _driverService.getDrivers();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Driver>>(
      future: _driversFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Text(
            snapshot.error.toString(),
          );
        }

        final drivers =
            snapshot.data ?? const <Driver>[];

       return DropdownButtonFormField<Driver>(
  initialValue: _selectedDriver,
  decoration: const InputDecoration(
    labelText: 'Assigned Driver',
    border: OutlineInputBorder(),
  ),
  items: [
    const DropdownMenuItem<Driver>(
      value: null,
      child: Text('No Driver Assigned'),
    ),
    ...drivers.map(
      (driver) => DropdownMenuItem<Driver>(
        value: driver,
        child: Text(driver.fullName),
      ),
    ),
  ],
  onChanged: (driver) {
    setState(() {
      _selectedDriver = driver;
    });

    widget.onChanged(driver);
  },
);
      },
    );
  }
}