import 'package:flutter/material.dart';

import '../app/constants.dart';

enum StatusBadgeTone { success, warning, critical, error, info, neutral }

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

  factory StatusBadge.critical(String label) => StatusBadge(
    label: label,
    tone: StatusBadgeTone.critical,
    icon: Icons.error,
  );

  factory StatusBadge.error(String label) => StatusBadge.critical(label);

  factory StatusBadge.info(String label) =>
      StatusBadge(label: label, tone: StatusBadgeTone.info, icon: Icons.info);

  factory StatusBadge.neutral(String label) => StatusBadge(
    label: label,
    tone: StatusBadgeTone.neutral,
    icon: Icons.info_outline,
  );

  Color _resolveColor() {
    if (color != null) return color!;
    switch (tone!) {
      case StatusBadgeTone.success:
        return AppConstants.successColor;
      case StatusBadgeTone.warning:
        return AppConstants.warningColor;
      case StatusBadgeTone.critical:
      case StatusBadgeTone.error:
        return AppConstants.dangerColor;
      case StatusBadgeTone.info:
        return AppConstants.infoColor;
      case StatusBadgeTone.neutral:
        return AppConstants.neutralColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedColor = _resolveColor();
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
