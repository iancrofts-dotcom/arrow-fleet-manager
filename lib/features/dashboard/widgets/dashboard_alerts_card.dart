import 'package:flutter/material.dart';

import '../models/dashboard_alert.dart';

class DashboardAlertsCard extends StatelessWidget {
  const DashboardAlertsCard({
    super.key,
    required this.alerts,
  });

  final List<DashboardAlert> alerts;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No fleet alerts. Everything looks good.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
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
         ...alerts.map(
  (alert) {
    final accentColor =
        alert.severity == DashboardAlertSeverity.critical
            ? Colors.red
            : Colors.orange;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
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
              leading: Icon(
                alert.icon,
                color: accentColor,
              ),
              title: Text(
                alert.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(alert.message),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ],
      ),
    );
  },
),
        ],
      ),
    );
  }
}