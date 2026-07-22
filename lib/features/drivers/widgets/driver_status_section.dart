import 'package:flutter/material.dart';

import '../../../shared/widgets/form_section.dart';

class DriverStatusSection extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;

  const DriverStatusSection({
    super.key,
    required this.isActive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FormSection(
      title: 'Account Status',
      subtitle: 'Control whether this driver can access the Driver Portal.',
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isActive
                    ? Icons.check_circle
                    : Icons.cancel,
                color: isActive
                    ? Colors.green
                    : Colors.red,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isActive
                      ? 'Driver account is active'
                      : 'Driver account is disabled',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Active Account'),
            subtitle: const Text(
              'Allow this driver to sign in to the mobile app.',
            ),
            value: isActive,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}