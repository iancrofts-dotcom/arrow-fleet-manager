import 'package:flutter/material.dart';

import '../models/dashboard_kpi.dart';

class DashboardKpiCard extends StatefulWidget {
  const DashboardKpiCard({
    super.key,
    required this.kpi,
    required this.icon,
    this.routeName,
  });

  final DashboardKpi kpi;
  final IconData icon;
  final String? routeName;

  @override
  State<DashboardKpiCard> createState() =>
      _DashboardKpiCardState();
}

class _DashboardKpiCardState
    extends State<DashboardKpiCard> {
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
    final route = widget.routeName;

    if (route == null || route.isEmpty) {
      return;
    }

    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final trendColor = _trendColor(context);

    return MouseRegion(
      cursor: widget.routeName != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Card(
            elevation: _hovering ? 6 : 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap:
                  widget.routeName != null ? _openRoute : null,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              trendColor.withValues(alpha: 0.15),
                          child: Icon(
                            widget.icon,
                            color: trendColor,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _trendIcon(),
                          color: trendColor,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Text(
                      widget.kpi.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      widget.kpi.value,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    const Spacer(),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.kpi.subtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: trendColor,
                                ),
                          ),
                        ),
                        if (widget.routeName != null)
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .primary,
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