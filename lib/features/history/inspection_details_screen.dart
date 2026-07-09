import 'package:flutter/material.dart';

import '../inspections/models/inspection.dart';

class InspectionDetailsScreen extends StatelessWidget {
  final Inspection inspection;

  const InspectionDetailsScreen({
    super.key,
    required this.inspection,
  });

  Widget buildRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inspection Details"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildRow(
                  "Inspection No.",
                  inspection.inspectionNumber,
                ),
                buildRow(
                  "Registration",
                  inspection.registration,
                ),
                buildRow(
                  "Driver",
                  inspection.driver,
                ),
                buildRow(
                  "Inspector",
                  inspection.inspector,
                ),
                buildRow(
                  "Mileage",
                  inspection.mileage.toString(),
                ),
                buildRow(
                  "Inspection Date",
                  inspection.inspectionDate.toString(),
                ),
                buildRow(
                  "Comments",
                  inspection.comments,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}