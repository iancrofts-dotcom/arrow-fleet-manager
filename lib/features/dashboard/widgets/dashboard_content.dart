import 'package:flutter/material.dart';

import '../models/dashboard_context.dart';

import '../sections/analytics_section.dart';
import '../sections/compliance_section.dart';
import '../sections/fleet_overview_section.dart';
import '../sections/maintenance_section.dart';
import '../sections/priority_section.dart';
import '../sections/quick_actions_section.dart';
import '../sections/dashboard_kpi_section.dart';
import 'dashboard_header.dart';
import 'responsive_dashboard_layout.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({
    super.key,
    required this.context,
    this.children = const [],
  });

  final DashboardContext context;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: this.context.onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeader(
              fleetHealth: this.context.fleetHealth,
            ),

            const SizedBox(height: 30),

            const DashboardKpiSection(),

            const SizedBox(height: 24),
            
            const QuickActionsSection(),

            const SizedBox(height: 30),

            ResponsiveDashboardLayout(
              leftColumn: [
                FleetOverviewSection(
                  summary: this.context.summary,
                ),

                PrioritySection(
                  summary: this.context.summary,
                ),

                ComplianceSection(
                  summary: this.context.summary,
                ),
              ],
              rightColumn: [
                MaintenanceSection(
                  summary: this.context.summary,
                ),

                AnalyticsSection(
                  summary: this.context.summary,
                ),

                ...children,
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}