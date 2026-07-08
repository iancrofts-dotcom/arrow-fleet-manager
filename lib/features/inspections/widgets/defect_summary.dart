import 'package:flutter/material.dart';

class DefectSummary extends StatelessWidget {
  final int completedChecks;
  final int totalChecks;
  final int defectCount;

  const DefectSummary({
    super.key,
    required this.completedChecks,
    required this.totalChecks,
    required this.defectCount,
  });

  @override
  Widget build(BuildContext context) {
    final ready = completedChecks == totalChecks;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.summarize),
                SizedBox(width: 10),
                Text(
                  "Inspection Summary",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _buildRow(
              "Checks Completed",
              "$completedChecks / $totalChecks",
            ),

            const SizedBox(height: 12),

            _buildRow(
              "Outstanding Defects",
              "$defectCount",
            ),

            const Divider(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  ready
                      ? Icons.check_circle
                      : Icons.pending_actions,
                  color: ready ? Colors.green : Colors.orange,
                ),

                const SizedBox(width: 10),

                Text(
                  ready
                      ? "Inspection Ready"
                      : "Inspection In Progress",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ready ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}