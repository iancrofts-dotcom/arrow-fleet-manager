import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../widgets/dashboard_button.dart';
import '../../widgets/stat_card.dart';
import '../inspections/inspection_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "Welcome",
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 5),

            const Text(
              AppConstants.companyName,
            ),

            const SizedBox(height: 25),

            const Text(
              "Today's Fleet",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Row(
              children: [

                Expanded(
                  child: StatCard(
                    title: "Vehicles",
                    value: "147",
                    icon: Icons.local_shipping,
                  ),
                ),

                SizedBox(width: 15),

                Expanded(
                  child: StatCard(
                    title: "Checks",
                    value: "12",
                    icon: Icons.assignment_turned_in,
                  ),
                ),

                SizedBox(width: 15),

                Expanded(
                  child: StatCard(
                    title: "Defects",
                    value: "2",
                    icon: Icons.warning,
                  ),
                ),

              ],
            ),

            const SizedBox(height: 35),

            const Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            DashboardButton(
              icon: Icons.assignment,
              title: "New Inspection",
              onPressed: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InspectionScreen(),
                  ),
                );

              },
            ),

            const SizedBox(height: 12),

            DashboardButton(
              icon: Icons.search,
              title: "Search Inspections",
              onPressed: () {},
            ),

            const SizedBox(height: 12),

            DashboardButton(
              icon: Icons.description,
              title: "Reports",
              onPressed: () {},
            ),

            const SizedBox(height: 12),

            DashboardButton(
              icon: Icons.settings,
              title: "Settings",
              onPressed: () {},
            ),

          ],
        ),
      ),
    );
  }
}