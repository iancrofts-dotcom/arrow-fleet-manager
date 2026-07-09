import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory StatusBadge.success(String label) {
    return StatusBadge(
      label: label,
      color: Colors.green,
      icon: Icons.check_circle,
    );
  }

  factory StatusBadge.warning(String label) {
    return StatusBadge(
      label: label,
      color: Colors.orange,
      icon: Icons.warning_amber_rounded,
    );
  }

  factory StatusBadge.error(String label) {
    return StatusBadge(
      label: label,
      color: Colors.red,
      icon: Icons.error,
    );
  }

  factory StatusBadge.info(String label) {
    return StatusBadge(
      label: label,
      color: Colors.blue,
      icon: Icons.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 6),
          ],
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