import 'package:flutter/material.dart';

class VehicleActionsSheet extends StatelessWidget {
  const VehicleActionsSheet({
    super.key,
    required this.onEdit,
    required this.onDeactivate,
  });

  final VoidCallback onEdit;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Vehicle'),
            onTap: onEdit,
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Deactivate Vehicle'),
            onTap: onDeactivate,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
