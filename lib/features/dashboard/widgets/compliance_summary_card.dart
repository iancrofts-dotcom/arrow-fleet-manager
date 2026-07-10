import 'package:flutter/material.dart';

class ComplianceSummaryCard extends StatelessWidget {
  final int motDue;
  final int serviceDue;
  final int overdue;

  const ComplianceSummaryCard({
    super.key,
    required this.motDue,
    required this.serviceDue,
    required this.overdue,
  });

  Widget _buildRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int value,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: CircleAvatar(
        radius: 14,
        child: Text(
          value.toString(),
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Upcoming Compliance",
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 16),

            _buildRow(
              context,
              icon: Icons.assignment_turned_in,
              title: "MOT Due",
              value: motDue,
            ),

            _buildRow(
              context,
              icon: Icons.build,
              title: "Service Due",
              value: serviceDue,
            ),

            _buildRow(
              context,
              icon: Icons.warning,
              title: "Overdue",
              value: overdue,
            ),
          ],
        ),
      ),
    );
  }
}