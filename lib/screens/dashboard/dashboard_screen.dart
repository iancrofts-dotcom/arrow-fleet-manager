import 'package:flutter/material.dart';
import '../inspection/inspection_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Arrow Specialised Transport"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            dashboardCard(
  context,
  Icons.assignment,
  "New Inspection",
  const InspectionScreen(),
),
            dashboardCard(
  context,
  Icons.search,
  "Search",
  const Scaffold(
    body: Center(child: Text("Coming Soon")),
  ),
),
           dashboardCard(
  context,
  Icons.search,
  "Search",
  const Scaffold(
    body: Center(child: Text("Coming Soon")),
  ),
),dashboardCard(
  context,
  Icons.search,
  "Search",
  const Scaffold(
    body: Center(child: Text("Coming Soon")),
  ),
),
          ],
        ),
      ),
    );
  }

  Widget dashboardCard(
  BuildContext context,
  IconData icon,
  String title,
  Widget page,
) {
  return Card(
    elevation: 5,
    child: InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => page,
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60),
          const SizedBox(height: 15),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}
}