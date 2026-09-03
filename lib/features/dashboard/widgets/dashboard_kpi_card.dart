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

  Color _accentColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (widget.kpi.title) {
      case 'Compliance':
        return scheme.tertiary;
      case 'Maintenance':
        return scheme.secondary;
      default:
        return scheme.primary;
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
    final accentColor = _accentColor(context);
    final scheme = Theme.of(context).colorScheme;
    final isInteractive = widget.onTap != null || widget.routeName != null;
    final phone = MediaQuery.sizeOf(context).width <= 480;

    return MouseRegion(
      cursor: isInteractive
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: isInteractive ? (_) => setState(() => _hovering = true) : null,
      onExit: isInteractive ? (_) => setState(() => _hovering = false) : null,
      child: Card(
        elevation: isInteractive && _hovering ? 4 : 1,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isInteractive ? _openRoute : null,
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  phone ? 10 : 18,
                  phone ? 10 : 20,
                  phone ? 10 : 18,
                  phone ? 16 : 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(phone ? 6 : 11),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            widget.icon,
                            color: accentColor,
                            size: phone ? 18 : 22,
                          ),
                        ),
                        const Spacer(),
                        if (isInteractive)
                          Icon(
                            Icons.arrow_forward,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),

                    SizedBox(height: phone ? 6 : 18),

                    Text(
                      widget.kpi.title.toUpperCase(),
                      style: phone
                          ? Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            )
                          : Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                            ),
                    ),

                    SizedBox(height: phone ? 2 : 4),

                    Text(
                      widget.kpi.value,
                      style:
                          (phone
                                  ? Theme.of(context).textTheme.titleLarge
                                  : Theme.of(context).textTheme.headlineMedium)
                              ?.copyWith(fontWeight: FontWeight.w800),
                    ),

                    const Spacer(),

                    Text(
                      widget.kpi.subtitle,
                      maxLines: phone ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (phone
                                  ? Theme.of(context).textTheme.labelSmall
                                  : Theme.of(context).textTheme.bodySmall)
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: phone ? 10 : 18,
                right: phone ? 10 : 18,
                bottom: phone ? 8 : 12,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
