import 'package:flutter/material.dart';
import '../../../app/constants.dart';

class InspectionHeader extends StatelessWidget {
  final String inspectionNumber;
  final DateTime inspectionDate;

  const InspectionHeader({
    super.key,
    required this.inspectionNumber,
    required this.inspectionDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_shipping,
                  color: AppConstants.primaryColor,
                  size: 40,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.appName,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        AppConstants.companyName,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 32),

            Row(
              children: [
                const Icon(Icons.badge_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Inspection Number",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  inspectionNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.calendar_today_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Inspection Date",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  "${inspectionDate.day.toString().padLeft(2, '0')}/"
                  "${inspectionDate.month.toString().padLeft(2, '0')}/"
                  "${inspectionDate.year}",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}