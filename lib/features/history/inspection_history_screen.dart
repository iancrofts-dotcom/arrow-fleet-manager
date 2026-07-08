import 'package:flutter/material.dart';

class InspectionHistoryScreen extends StatelessWidget {
  const InspectionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection History'),
      ),
      body: const Center(
        child: Text(
          'No inspections saved yet.',
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}