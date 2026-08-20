import 'package:flutter/material.dart';

class DeactivateVehicleDialog extends StatelessWidget {
  const DeactivateVehicleDialog({super.key, required this.registration});

  final String registration;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Deactivate Vehicle"),
      content: Text(
        "Deactivate vehicle '$registration'?\n\nThe vehicle will become "
        'inactive. Its maintenance, inspections, assignments and records '
        'will be retained.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Deactivate"),
        ),
      ],
    );
  }
}
