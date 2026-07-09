import 'package:flutter/material.dart';

class VehicleActionsSheet extends StatelessWidget {
  const VehicleActionsSheet({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
            title: const Text('Delete Vehicle'),
            onTap: onDelete,
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