import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../widgets/app_header.dart';
import '../../widgets/dashboard_button.dart';
import '../../widgets/stat_card.dart';
import '../inspections/inspection_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.padding),
          children: [
            const AppHeader(
              title: AppConstants.appName,
              subtitle: AppConstants.companyName,
            ),

            const SizedBox(height: 25),

            const Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: "Vehicles",
                    value: "${AppConstants.totalVehicles}",
                    icon: Icons.local_shipping,
                    color: AppConstants.primaryColor,
                  ),
                ),

                SizedBox(width: 15),

                Expanded(
                  child: StatCard(
                    title: "Today's Checks",
                    value: "${AppConstants.inspectionsToday}",
                    icon: Icons.assignment_turned_in,
                    color: AppConstants.successColor,
                  ),
                ),

                SizedBox(width: 15),

                Expanded(
                  child: StatCard(
                    title: "Defects",
                    value: "${AppConstants.outstandingDefects}",
                    icon: Icons.warning,
                    color: AppConstants.dangerColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Text(
              "Quick Actions",
              style: Theme.of(context).textTheme.headlineSmall,
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
              icon: Icons.local_shipping,
              title: "Vehicles",
              onPressed: () {},
            ),

            const SizedBox(height: 12),

            DashboardButton(
              icon: Icons.bar_chart,
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