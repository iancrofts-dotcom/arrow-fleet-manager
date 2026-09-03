import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/status_badge.dart';
import '../../auth/services/auth_service.dart';
import '../models/fleet_health.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, required this.fleetHealth});

  final FleetHealth fleetHealth;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  StatusBadge _healthBadge() {
    switch (fleetHealth.status) {
      case FleetHealthStatus.excellent:
      case FleetHealthStatus.good:
        return StatusBadge.success(fleetHealth.label);
      case FleetHealthStatus.fair:
      case FleetHealthStatus.poor:
        return StatusBadge.warning(fleetHealth.label);
      case FleetHealthStatus.critical:
        return StatusBadge.critical(fleetHealth.label);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final username = AuthService.instance.currentUser?.username ?? 'User';

    return LayoutBuilder(
      builder: (context, constraints) {
        final phone = constraints.maxWidth <= 480;
        final stacked = constraints.maxWidth < 700;
        final health = _HealthStatus(
          fleetHealth: fleetHealth,
          badge: _healthBadge(),
          compact: phone,
        );

        return Card(
          elevation: 0,
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.34),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.22),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(phone ? 16 : 22),
            child: stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Greeting(
                        greeting: _greeting(),
                        username: username,
                        date: now,
                        theme: theme,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [health],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _Greeting(
                          greeting: _greeting(),
                          username: username,
                          date: now,
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 32),
                      health,
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.greeting,
    required this.username,
    required this.date,
    required this.theme,
  });

  final String greeting;
  final String username;
  final DateTime date;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$greeting, $username',
        key: const Key('dashboard-greeting'),
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Fleet operations overview for ${DateFormat('EEEE, d MMMM').format(date)}',
        style: theme.textTheme.bodyMedium,
      ),
    ],
  );
}

class _HealthStatus extends StatelessWidget {
  const _HealthStatus({
    required this.fleetHealth,
    required this.badge,
    required this.compact,
  });

  final FleetHealth fleetHealth;
  final StatusBadge badge;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final score = Text(
      fleetHealth.formattedScore,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: fleetHealth.colour,
        fontWeight: FontWeight.w900,
      ),
    );

    return Container(
      key: const Key('dashboard-fleet-health'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fleet Health',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [score, badge],
                ),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fleet Health',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    score,
                  ],
                ),
                const SizedBox(width: 10),
                badge,
              ],
            ),
    );
  }
}
