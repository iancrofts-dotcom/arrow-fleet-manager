import 'package:flutter/material.dart';

class DeleteVehicleDialog extends StatelessWidget {
  const DeleteVehicleDialog({
    super.key,
    required this.registration,
  });

  final String registration;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Delete Vehicle"),
      content: Text(
        "Delete vehicle '$registration'?\n\nThis action cannot be undone.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Delete"),
        ),
      ],
    );
  }
}