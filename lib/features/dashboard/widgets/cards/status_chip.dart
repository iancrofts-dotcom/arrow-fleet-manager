import 'package:flutter/material.dart';

enum StatusChipState {
  healthy,
  warning,
  error,
  inactive,
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.state,
  });

  final String label;
  final StatusChipState state;

  Color _color(BuildContext context) {
    switch (state) {
      case StatusChipState.healthy:
        return Colors.green;

      case StatusChipState.warning:
        return Colors.orange;

      case StatusChipState.error:
        return Colors.red;

      case StatusChipState.inactive:
        return Colors.grey;
    }
  }

  IconData _icon() {
    switch (state) {
      case StatusChipState.healthy:
        return Icons.check_circle;

      case StatusChipState.warning:
        return Icons.warning;

      case StatusChipState.error:
        return Icons.error;

      case StatusChipState.inactive:
        return Icons.remove_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon(),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}