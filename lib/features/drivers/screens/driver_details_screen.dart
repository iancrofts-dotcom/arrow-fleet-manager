import 'package:flutter/material.dart';

import '../models/driver.dart';
import 'edit_driver_screen.dart';

class DriverDetailsScreen extends StatelessWidget {
  const DriverDetailsScreen({
    super.key,
    required this.driver,
  });

  final Driver driver;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(driver.fullName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    child: Text(
                      driver.firstName.substring(0, 1),
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    driver.fullName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    driver.licenceNumber,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          _detailTile(
  context,
  Icons.phone,
  'Phone',
  driver.phone.isNotEmpty
      ? driver.phone
      : 'Not provided',
),

_detailTile(
  context,
  Icons.email,
  'Email',
  driver.email.isNotEmpty
      ? driver.email
      : 'Not provided',
),

          _detailTile(
            context,
            Icons.badge,
            'Licence Number',
            driver.licenceNumber,
          ),

          _detailTile(
            context,
            Icons.calendar_today,
            'Licence Expiry',
            driver.licenceExpiry != null
                ? _formatDate(driver.licenceExpiry!)
                : 'Not set',
          ),

          const SizedBox(height: 24),

          Card(
            child: ListTile(
              leading: const Icon(Icons.verified_user),
              title: const Text('Driver Compliance'),
              subtitle: const Text(
                'Compliance management will be enabled in the next step.',
              ),
            ),
          ),

          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditDriverScreen(
                    driver: driver,
                  ),
                ),
              );

              if (context.mounted) {
                Navigator.pop(context, true);
              }
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Driver'),
          ),
        ],
      ),
    );
  }

  Widget _detailTile(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}