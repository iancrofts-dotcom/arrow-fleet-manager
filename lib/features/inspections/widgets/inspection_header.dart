import 'package:flutter/material.dart';

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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Arrow Specialised Transport",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "Inspection No: $inspectionNumber",
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 10),

            Text(
              "Date: ${inspectionDate.day}/${inspectionDate.month}/${inspectionDate.year}",
            ),
          ],
        ),
      ),
    );
  }
}