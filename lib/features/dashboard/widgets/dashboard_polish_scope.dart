import 'package:flutter/material.dart';

/// Dashboard-only visual refinement layer.
///
/// Keeps the existing FleetIQ dashboard structure, data, permissions,
/// navigation and widgets intact while making their shared Material treatment
/// more consistent across Web, Windows and Android.
class DashboardPolishScope extends StatelessWidget {
  const DashboardPolishScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final scheme = base.colorScheme;

    return Theme(
      data: base.copyWith(
        cardTheme: base.cardTheme.copyWith(
          elevation: 0,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.75),
            ),
          ),
        ),
        dividerTheme: base.dividerTheme.copyWith(
          color: scheme.outlineVariant.withValues(alpha: 0.7),
          space: 1,
          thickness: 1,
        ),
        listTileTheme: base.listTileTheme.copyWith(
          minVerticalPadding: 12,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        textTheme: base.textTheme.copyWith(
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.25,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.35),
        ),
      ),
      child: child,
    );
  }
}
