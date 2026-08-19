import 'package:flutter/material.dart';

import '../../../shared/widgets/app_page_scaffold.dart';
import '../../auth/services/permission_service.dart';
import '../models/workshop_inspection.dart';
import '../repositories/workshop_repository.dart';
import 'new_workshop_inspection_screen.dart';
import 'workshop_inspection_details_screen.dart';

class WorkshopInspectionScreen extends StatefulWidget {
  const WorkshopInspectionScreen({super.key});

  @override
  State<WorkshopInspectionScreen> createState() =>
      _WorkshopInspectionScreenState();
}

class _WorkshopInspectionScreenState
    extends State<WorkshopInspectionScreen> {
  final WorkshopRepository _repository = WorkshopRepository();

  late Future<List<WorkshopInspection>> _future;

  @override
  void initState() {
    super.initState();
    _loadInspections();
  }

  void _loadInspections() {
    _future = _repository.getAllInspections();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadInspections();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.instance.canManageWorkshop) {
      return const _WorkshopInspectionsAccessDenied();
    }

    return AppPageScaffold(
      title: 'Workshop Inspections',
      subtitle: 'Vehicle inspections, Driver Daily submissions and sign-off status.',
      floatingActionButton: FloatingActionButton.extended(
       onPressed: () async {
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const NewWorkshopInspectionScreen(),
    ),
  );

  _refresh();
},
        icon: const Icon(Icons.add),
        label: const Text('New Inspection'),
      ),
      child: FutureBuilder<List<WorkshopInspection>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(label: 'Loading Workshop inspections...');
          }

          if (snapshot.hasError) {
            return AppErrorState(
              message: 'Unable to load inspections.\n\n${snapshot.error}',
              onRetry: _refresh,
            );
          }

          final inspections = snapshot.data ?? [];

          if (inspections.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  AppEmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'No Workshop inspections found',
                    message: 'Use New Inspection to create one.',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: inspections.length,
              separatorBuilder: (context, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final inspection = inspections[index];
                final driverName = inspection.driverName;
                final submittedBy = driverName != null &&
                        driverName.trim().isNotEmpty
                    ? 'Driver: $driverName'
                    : 'Technician: ${inspection.technicianName}';

                return Card(
                  elevation: 2,
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.assignment),
                    ),
                    title: Text(
                      inspection.registration,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${inspection.inspectionNumber}\n'
                      '${inspection.templateName?.trim().isNotEmpty == true ? inspection.templateName : _inspectionTypeLabel(inspection.inspectionType)}\n'
                      '$submittedBy\n'
                      'Submitted: ${_dateTimeLabel(inspection.dateStarted)}\n'
                      'Result: ${inspection.overallResult.name} • Repairs: ${inspection.repairsRequired}',
                    ),
                    isThreeLine: false,
                    trailing: Chip(
                      label: Text(
                        inspection.status.name,
                      ),
                    ),
                    onTap: () {
                      final inspectionId = inspection.id;

                      if (inspectionId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'This inspection does not have a database ID.',
                            ),
                          ),
                        );
                        return;
                      }

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              WorkshopInspectionDetailsScreen(
                            inspectionId: inspectionId,
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

  String _inspectionTypeLabel(WorkshopInspectionType type) {
    if (type == WorkshopInspectionType.driverDailyInspection) {
      return 'Driver Daily Inspection';
    }

    return type.name;
  }

  String _dateTimeLabel(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}

class _WorkshopInspectionsAccessDenied extends StatelessWidget {
  const _WorkshopInspectionsAccessDenied();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Access Denied')),
      body: const Center(
        child: Text('You do not have permission to view Workshop inspections.'),
      ),
    );
  }
}
