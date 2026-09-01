import 'package:flutter/material.dart';

import '../models/dashboard_kpi.dart';

class DashboardKpiCard extends StatefulWidget {
  const DashboardKpiCard({
    super.key,
    required this.kpi,
    required this.icon,
    this.routeName,
    this.onTap,
  });

  final DashboardKpi kpi;
  final IconData icon;
  final String? routeName;
  final VoidCallback? onTap;

  @override
  State<DashboardKpiCard> createState() => _DashboardKpiCardState();
}

class _DashboardKpiCardState extends State<DashboardKpiCard> {
  bool _hovering = false;

  Color _trendColor(BuildContext context) {
    switch (widget.kpi.trend) {
      case DashboardKpiTrend.up:
        return Colors.green;

      case DashboardKpiTrend.down:
        return Colors.orange;

      case DashboardKpiTrend.stable:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _trendIcon() {
    switch (widget.kpi.trend) {
      case DashboardKpiTrend.up:
        return Icons.trending_up;

      case DashboardKpiTrend.down:
        return Icons.trending_down;

      case DashboardKpiTrend.stable:
        return Icons.trending_flat;
    }
  }

  void _openRoute() {
    final onTap = widget.onTap;
    if (onTap != null) {
      onTap();
      return;
    }

    final route = widget.routeName;

    if (route == null || route.isEmpty) {
      return;
    }

    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final trendColor = _trendColor(context);
    final isInteractive = widget.onTap != null || widget.routeName != null;

    return MouseRegion(
      cursor: isInteractive
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.01 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovering
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: isInteractive ? _openRoute : null,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: trendColor.withValues(alpha: 0.15),
                          child: Icon(widget.icon, color: trendColor),
                        ),
                        const Spacer(),
                        Icon(_trendIcon(), color: trendColor),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Text(
                      widget.kpi.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      widget.kpi.value,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),

                    const Spacer(),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.kpi.subtitle,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(color: trendColor),
                          ),
                        ),
                        if (isInteractive)
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
