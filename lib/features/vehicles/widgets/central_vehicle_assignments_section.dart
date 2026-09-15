import 'package:flutter/material.dart';

import '../../../shared/status_badge.dart';
import '../../../backend/drivers/backend_driver_assignment.dart';
import '../../../backend/drivers/central_driver_assignment_write_service.dart';
import '../../auth/services/permission_service.dart';
import '../screens/central_assign_driver_screen.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../models/central_vehicle_assignment.dart';
import '../models/vehicle_identity.dart';
import '../services/central_vehicle_assignment_read_service.dart';

class CentralVehicleAssignmentsSection extends StatefulWidget {
  const CentralVehicleAssignmentsSection({
    super.key,
    required this.vehicleIdentity,
    this.assignmentReadService,
  });

  final VehicleIdentity vehicleIdentity;
  final CentralVehicleAssignmentReadService? assignmentReadService;

  @override
  State<CentralVehicleAssignmentsSection> createState() =>
      _CentralVehicleAssignmentsSectionState();
}

class _CentralVehicleAssignmentsSectionState
    extends State<CentralVehicleAssignmentsSection> {
  late final CentralVehicleAssignmentReadService _assignmentReadService;
  late Future<List<CentralVehicleAssignment>> _assignmentsFuture;

  @override
  void initState() {
    super.initState();
    if (widget.vehicleIdentity.centralIdOrNull == null) {
      throw ArgumentError('Central Vehicle assignments require UUID identity.');
    }
    _assignmentReadService =
        widget.assignmentReadService ??
        CentralVehicleAssignmentReadService.forSupabase();
    _loadAssignments();
  }

  void _loadAssignments() {
    _assignmentsFuture = _assignmentReadService.getAssignmentsForVehicle(
      widget.vehicleIdentity,
    );
  }

  Future<void> _refreshAssignments() async {
    setState(_loadAssignments);
    await _assignmentsFuture;
  }

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Driver assignments',
    subtitle: 'Current and previous central Driver assignments.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (PermissionService.instance.canManageVehicles) ...[
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _assignDriver,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Assign / Change Driver'),
              ),
              OutlinedButton.icon(
                onPressed: _endCurrentAssignment,
                icon: const Icon(Icons.link_off_outlined),
                label: const Text('End Current Assignment'),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        FutureBuilder<List<CentralVehicleAssignment>>(
          future: _assignmentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: AppLoadingState(label: 'Loading assignments...'),
              );
            }
            if (snapshot.hasError) {
              return AppErrorState(
                title: 'Unable to load assignments',
                message:
                    'The Vehicle profile is available, but assignment data could not be loaded.',
                onRetry: _refreshAssignments,
              );
            }

            final assignments =
                snapshot.data ?? const <CentralVehicleAssignment>[];
            if (assignments.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: AppEmptyState(
                  icon: Icons.person_off_outlined,
                  title: 'No assignments',
                  message:
                      'No central Driver assignments are recorded for this Vehicle.',
                ),
              );
            }

            final current = assignments.where((row) => row.isCurrent).toList();
            final history = assignments.where((row) => !row.isCurrent).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (current.isNotEmpty) ...[
                  Text(
                    'Current',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  ...current.map((row) => _assignmentTile(row, current: true)),
                ],
                if (history.isNotEmpty) ...[
                  if (current.isNotEmpty) const SizedBox(height: 12),
                  Text(
                    'History',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  ...history.map(_assignmentTile),
                ],
              ],
            );
          },
        ),
      ],
    ),
  );

  Future<void> _assignDriver() async {
    final vehicleId = widget.vehicleIdentity.centralIdOrNull!;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CentralAssignDriverScreen(
          vehicleId: vehicleId,
          vehicleLabel: 'this Vehicle',
        ),
      ),
    );
    if (changed == true && mounted) await _refreshAssignments();
  }

  Future<void> _endCurrentAssignment() async {
    final assignments = await _assignmentReadService.getAssignmentsForVehicle(
      widget.vehicleIdentity,
    );
    final active = assignments
        .where((row) => row.isCurrent)
        .toList(growable: false);
    if (active.isEmpty || !mounted) return;
    final row = active.first;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('End Driver Assignment?'),
        content: Text(
          'End the current assignment for ${row.driverName}? The history will be retained.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('End Assignment'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await CentralDriverAssignmentWriteService().end(
        BackendDriverAssignment(
          id: row.id,
          driverId: row.driverId,
          vehicleId: row.vehicleId,
          assignedFrom: row.assignedFrom,
          assignedTo: row.assignedTo,
          isActive: row.isActive,
          createdAt: row.assignedFrom,
          updatedAt: row.assignedFrom,
        ),
      );
      if (mounted) await _refreshAssignments();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to end assignment: $error')),
      );
    }
  }

  Widget _assignmentTile(
    CentralVehicleAssignment assignment, {
    bool current = false,
  }) => Card(
    child: ListTile(
      leading: Icon(current ? Icons.person_outline : Icons.history_outlined),
      title: Text(assignment.driverLabel),
      subtitle: Text(_assignmentPeriod(assignment)),
      trailing: current
          ? StatusBadge.success('Current')
          : StatusBadge.neutral('Ended'),
    ),
  );

  String _assignmentPeriod(CentralVehicleAssignment assignment) {
    final start = _formatDateTime(assignment.assignedFrom);
    final end = assignment.assignedTo == null
        ? 'Present'
        : _formatDateTime(assignment.assignedTo!);
    return '$start — $end';
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
