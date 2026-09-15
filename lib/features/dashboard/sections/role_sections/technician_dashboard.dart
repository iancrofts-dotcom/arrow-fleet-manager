import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_page_scaffold.dart';
import '../../../auth/screens/central/central_my_profile_screen.dart';

class TechnicianDashboard extends StatelessWidget {
  const TechnicianDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SectionCard(
          title: 'Technician Workspace',
          subtitle:
              'Open assigned Workshop work or manage your FleetIQ profile.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/workshop'),
                icon: const Icon(Icons.handyman_outlined),
                label: const Text('Open My Repair Jobs'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    fullscreenDialog: true,
                    builder: (_) => const CentralMyProfileScreen(),
                  ),
                ),
                icon: const Icon(Icons.account_circle_outlined),
                label: const Text('My Profile & Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
