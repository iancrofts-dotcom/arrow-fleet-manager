import 'package:flutter/material.dart';

class MaintenanceSummaryCard extends StatelessWidget {
  const MaintenanceSummaryCard({
    super.key,
    required this.overdue,
    required this.dueSoon,
    required this.scheduled,
    required this.estimatedCost,
  });

  final int overdue;
  final int dueSoon;
  final int scheduled;
  final double estimatedCost;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Maintenance Summary',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),

            const SizedBox(height: 20),

            _summaryRow(
              Icons.warning,
              Colors.red,
              'Overdue',
              overdue.toString(),
            ),

            _summaryRow(
              Icons.schedule,
              Colors.orange,
              'Due Soon',
              dueSoon.toString(),
            ),

            _summaryRow(
              Icons.build,
              Colors.blue,
              'Scheduled',
              scheduled.toString(),
            ),

            const Divider(height: 32),

            _summaryRow(
              Icons.currency_pound,
              Colors.green,
              'Estimated Cost',
              '£${estimatedCost.toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    IconData icon,
    Color color,
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(title),
          ),

          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}