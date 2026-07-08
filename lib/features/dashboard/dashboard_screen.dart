import 'package:flutter/material.dart';

import '../history/inspection_history_screen.dart';
import '../inspections/inspection_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arrow Fleet Manager'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.assignment),
              label: const Text('New Inspection'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InspectionScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            FilledButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('Inspection History'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InspectionHistoryScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}