import 'package:flutter/material.dart';

import '../../database/database_service.dart';
import '../../database/inspection_repository.dart';
import 'inspection_details_screen.dart';

class InspectionHistoryScreen extends StatefulWidget {
  const InspectionHistoryScreen({super.key});

  @override
  State<InspectionHistoryScreen> createState() =>
      _InspectionHistoryScreenState();
}

class _InspectionHistoryScreenState
    extends State<InspectionHistoryScreen> {
  late final InspectionRepository repository;
  late Future<List<Map<String, dynamic>>> inspectionsFuture;

  @override
  void initState() {
    super.initState();

    repository = InspectionRepository(
      databaseService: DatabaseService(),
    );

    inspectionsFuture = repository.getInspections();
  }

  Future<void> refresh() async {
    setState(() {
      inspectionsFuture = repository.getInspections();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inspection History"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: inspectionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          final inspections = snapshot.data ?? [];

          if (inspections.isEmpty) {
            return const Center(
              child: Text(
                "No inspections found.",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView.builder(
              itemCount: inspections.length,
              itemBuilder: (context, index) {
                final inspection = inspections[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.assignment),
                    title: Text(
                      inspection["inspectionNumber"] ?? "",
                    ),
                    subtitle: Text(
                      "${inspection["registration"]}\n${inspection["driver"]}",
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InspectionDetailsScreen(
                            inspection: inspection,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}