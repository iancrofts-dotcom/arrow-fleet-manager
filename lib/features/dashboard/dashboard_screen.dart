import 'package:flutter/material.dart';
import '../../widgets/stat_card.dart';
import '../inspections/inspection_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Arrow Fleet Manager"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Today's Activity",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: const [

                  StatCard(
                    title: "Inspections",
                    value: "12",
                    icon: Icons.assignment,
                  ),

                  StatCard(
                    title: "Defects",
                    value: "2",
                    icon: Icons.warning,
                  ),

                  StatCard(
                    title: "Vehicles",
                    value: "147",
                    icon: Icons.local_shipping,
                  ),

                ],
              ),
            ),

            const SizedBox(height: 10),

            FilledButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const InspectionScreen(),
      ),
    );
  },
  icon: const Icon(Icons.assignment),
  label: const Text("New Inspection"),
),

            const SizedBox(height: 10),

            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.search),
              label: const Text("Search Inspections"),
            ),

          ],
        ),
      ),
    );
  }
}