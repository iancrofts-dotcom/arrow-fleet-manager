import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../auth/services/auth_service.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final username = AuthService.instance.currentUser?.username ?? 'User';

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.34),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: _Greeting(
          greeting: _greeting(),
          username: username,
          date: now,
          theme: theme,
        ),
      ),
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
