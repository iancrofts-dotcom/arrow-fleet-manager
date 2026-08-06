import 'package:flutter/material.dart';

import '../models/workshop_inspection.dart';
import '../repositories/workshop_repository.dart';

class WorkshopInspectionListScreen extends StatefulWidget {
  const WorkshopInspectionListScreen({super.key});

  @override
  State<WorkshopInspectionListScreen> createState() =>
      _WorkshopInspectionListScreenState();
}

class _WorkshopInspectionListScreenState
    extends State<WorkshopInspectionListScreen> {
  final WorkshopRepository _repository = WorkshopRepository();

  late Future<List<WorkshopInspection>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.getAllInspections();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _repository.getAllInspections();
    });
  }

  Color _statusColor(WorkshopInspection inspection) {
    switch (inspection.status) {
      case WorkshopInspectionStatus.completed:
        return Colors.green;

      case WorkshopInspectionStatus.inProgress:
        return Colors.orange;

      case WorkshopInspectionStatus.cancelled:
        return Colors.red;

      default:
        return Colors.blue;
    }
  }

  String _statusText(WorkshopInspection inspection) {
    return inspection.status.name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workshop Inspections'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Next sprint
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<WorkshopInspection>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  snapshot.error.toString(),
                ),
              );
            }

            final inspections = snapshot.data ?? [];

            if (inspections.isEmpty) {
              return const Center(
                child: Text(
                  'No workshop inspections found.',
                ),
              );
            }

            return ListView.builder(
              itemCount: inspections.length,
              itemBuilder: (context, index) {
                final inspection = inspections[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          _statusColor(inspection),
                      child: const Icon(
                        Icons.build,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      inspection.registration,
                    ),
                    subtitle: Text(
                      inspection.inspectionType.name,
                    ),
                    trailing: Chip(
                      label: Text(
                        _statusText(inspection),
                      ),
                    ),
                    onTap: () {
                      // Sprint 20.2
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}