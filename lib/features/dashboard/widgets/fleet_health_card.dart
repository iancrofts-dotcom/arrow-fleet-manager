import 'package:flutter/material.dart';

class FleetHealthCard extends StatelessWidget {
  final int healthScore;

  const FleetHealthCard({
    super.key,
    required this.healthScore,
  });

  String get status {
    if (healthScore >= 90) return "Excellent";
    if (healthScore >= 75) return "Good";
    if (healthScore >= 50) return "Needs Attention";
    return "Critical";
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
              "Fleet Health",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 20),

            LinearProgressIndicator(
              value: healthScore / 100,
              minHeight: 10,
              borderRadius: BorderRadius.circular(20),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$healthScore%",
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(status),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}