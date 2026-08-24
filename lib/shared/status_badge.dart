import 'package:flutter/material.dart';

enum StatusBadgeTone { success, warning, error, info, neutral }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.tone,
  }) : assert(color != null || tone != null);

  final String label;
  final Color? color;
  final IconData? icon;
  final StatusBadgeTone? tone;

  factory StatusBadge.success(String label) => StatusBadge(
    label: label,
    tone: StatusBadgeTone.success,
    icon: Icons.check_circle,
  );

  factory StatusBadge.warning(String label) => StatusBadge(
    label: label,
    tone: StatusBadgeTone.warning,
    icon: Icons.warning_amber_rounded,
  );

  factory StatusBadge.error(String label) =>
      StatusBadge(label: label, tone: StatusBadgeTone.error, icon: Icons.error);

  factory StatusBadge.info(String label) =>
      StatusBadge(label: label, tone: StatusBadgeTone.info, icon: Icons.info);

  factory StatusBadge.neutral(String label) => StatusBadge(
    label: label,
    tone: StatusBadgeTone.neutral,
    icon: Icons.info_outline,
  );

  Color _resolveColor(ColorScheme scheme) {
    if (color != null) return color!;
    switch (tone!) {
      case StatusBadgeTone.success:
        return scheme.primary;
      case StatusBadgeTone.warning:
        return Colors.orange.shade800;
      case StatusBadgeTone.error:
        return scheme.error;
      case StatusBadgeTone.info:
        return scheme.secondary;
      case StatusBadgeTone.neutral:
        return scheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedColor = _resolveColor(Theme.of(context).colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: resolvedColor.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: resolvedColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(color: resolvedColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
