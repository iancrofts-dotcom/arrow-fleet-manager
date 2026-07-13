import 'package:flutter/material.dart';

import '../models/driver.dart';

class DriverCard extends StatelessWidget {
  final Driver driver;
  final VoidCallback? onTap;

  const DriverCard({
    super.key,
    required this.driver,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Text(
            driver.firstName.isNotEmpty
                ? driver.firstName[0].toUpperCase()
                : '?',
          ),
        ),
        title: Text(driver.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Licence: ${driver.licenceNumber}',
            ),
            Text(driver.email),
            Text(driver.phone),
          ],
        ),
        trailing: Icon(
          driver.active
              ? Icons.check_circle
              : Icons.cancel,
          color: driver.active
              ? Colors.green
              : Colors.red,
        ),
      ),
    );
  }
}