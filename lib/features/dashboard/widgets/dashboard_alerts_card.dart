import 'package:flutter/material.dart';
import '../../../core/navigation/dashboard_navigation.dart';
import '../models/dashboard_alert.dart';

class DashboardAlertsCard extends StatelessWidget {
  const DashboardAlertsCard({super.key, required this.alerts});

  final List<DashboardAlert> alerts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (alerts.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Expanded(child: Text('No fleet alerts. Everything looks good.')),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text(
              'Fleet Alerts',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${alerts.length} active'),
          ),
          const Divider(height: 1),
          ...alerts.map((alert) {
            final accentColor =
                alert.severity == DashboardAlertSeverity.critical
                ? Colors.red
                : Colors.orange;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 72,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      leading: Icon(alert.icon, color: accentColor),
                      title: Text(
                        alert.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(alert.message),
                      trailing: DashboardNavigation.canOpenRoute(alert.route)
                          ? const Icon(Icons.chevron_right)
                          : null,
                      onTap: DashboardNavigation.canOpenRoute(alert.route)
                          ? () => DashboardNavigation.openRoute(
                              context,
                              alert.route,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
