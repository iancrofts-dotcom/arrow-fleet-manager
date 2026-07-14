import 'package:flutter/material.dart';

import '../models/driver.dart';
import 'driver_assignment_picker.dart';

class DriverAssignmentDialog extends StatefulWidget {
  const DriverAssignmentDialog({
    super.key,
    this.initialDriver,
  });

  final Driver? initialDriver;

  @override
  State<DriverAssignmentDialog> createState() =>
      _DriverAssignmentDialogState();
}

class _DriverAssignmentDialogState
    extends State<DriverAssignmentDialog> {
  Driver? _selectedDriver;

  @override
  void initState() {
    super.initState();
    _selectedDriver = widget.initialDriver;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign Driver'),
      content: SizedBox(
        width: 420,
        child: DriverAssignmentPicker(
          selectedDriver: _selectedDriver,
          onChanged: (driver) {
            setState(() {
              _selectedDriver = driver;
            });
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              _selectedDriver,
            );
          },
          child: Text(
            _selectedDriver == null
                ? 'Assign Later'
                : 'Assign',
          ),
        ),
      ],
    );
  }
}