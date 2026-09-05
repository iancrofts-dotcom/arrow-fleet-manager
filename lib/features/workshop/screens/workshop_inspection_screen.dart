import 'package:flutter/material.dart';

import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/status_badge.dart';
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

class _WorkshopInspectionScreenState extends State<WorkshopInspectionScreen> {
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
      subtitle:
          'Vehicle inspections, Driver Daily submissions and sign-off status.',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const NewWorkshopInspectionScreen(),
            ),
          );

          if (created == true && mounted) {
            await _refresh();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Inspection'),
      ),
      child: FutureBuilder<List<WorkshopInspection>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(
              label: 'Loading Workshop inspections...',
            );
          }

          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Unable to load inspections',
              message: 'Please try again.',
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
                final submittedBy =
                    driverName != null && driverName.trim().isNotEmpty
                    ? 'Driver: $driverName'
                    : 'Technician: ${inspection.technicianName}';

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.assignment_outlined,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      inspection.inspectionNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${inspection.registration} | ${inspection.fleetNumber}\n'
                      '${inspection.templateName?.trim().isNotEmpty == true ? inspection.templateName : _inspectionTypeLabel(inspection.inspectionType)}\n'
                      '$submittedBy\n'
                      'Submitted: ${_dateTimeLabel(inspection.dateStarted)}\n'
                      'Result: ${inspection.overallResult.name} • Repairs: ${inspection.repairsRequired}',
                    ),
                    isThreeLine: false,
                    trailing: _statusBadge(inspection.status.name),
                    onTap: () async {
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

                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WorkshopInspectionDetailsScreen(
                            inspectionId: inspectionId,
                          ),
                        ),
                      );

                      if (mounted) {
                        await _refresh();
                      }
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
    return type.label;
  }

  StatusBadge _statusBadge(String status) {
    switch (status) {
      case 'signedOff':
        return StatusBadge.success('Signed Off');
      case 'completed':
        return StatusBadge.success('Completed');
      case 'cancelled':
        return StatusBadge.neutral('Cancelled');
      case 'awaitingRepair':
        return StatusBadge.warning('Awaiting Repair');
      case 'draft':
        return StatusBadge.neutral('Draft');
      case 'inProgress':
        return StatusBadge.info('In Progress');
      default:
        return StatusBadge.info(status);
    }
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
