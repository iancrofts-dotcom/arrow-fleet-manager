import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../auth/models/user_role.dart';
import '../../auth/services/auth_service.dart';
import '../models/fleet_health.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.fleetHealth,
  });

  final FleetHealth fleetHealth;

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  IconData _roleIcon(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;

      case UserRole.manager:
        return Icons.manage_accounts;

      case UserRole.workshop:
        return Icons.build;

      case UserRole.technician:
        return Icons.handyman_outlined;

      case UserRole.driver:
        return Icons.drive_eta;

     

      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    final currentUser = AuthService.instance.currentUser;
    final currentRole = AuthService.instance.currentRole;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mobile = constraints.maxWidth < 700;

            if (mobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLeft(
                    theme,
                    now,
                    currentUser?.username ?? "User"
                  ),
                  const SizedBox(height: 24),
                  _buildRight(
                    theme,
                    currentRole,
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildLeft(
                    theme,
                    now,
                    currentUser?.username ?? "User"
                  ),
                ),
                const SizedBox(width: 24),
                _buildRight(
                  theme,
                  currentRole,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeft(
    ThemeData theme,
    DateTime now,
    String userName,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${_greeting()}, $userName",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          DateFormat('EEEE, d MMMM yyyy').format(now),
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildRight(
    ThemeData theme,
    UserRole? role,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none),
            SizedBox(width: 6),
            Text("3"),
          ],
        ),
        const SizedBox(height: 20),
        Chip(
          avatar: Icon(
            _roleIcon(role),
            size: 18,
          ),
          label: Text(
            role?.displayName ?? "Unknown",
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite,
              color: fleetHealth.colour,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Fleet Health ${fleetHealth.formattedScore}",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: fleetHealth.colour,
                  ),
                ),
                Text(
                  fleetHealth.label,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
