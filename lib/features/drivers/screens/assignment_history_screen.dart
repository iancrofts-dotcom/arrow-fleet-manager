import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../models/driver_vehicle_assignment.dart';
import '../repositories/driver_assignment_repository.dart';
import '../services/driver_service.dart';

class AssignmentHistoryScreen extends StatefulWidget {
  const AssignmentHistoryScreen({
    super.key,
    required this.vehicleId,
  });

  final int vehicleId;

  @override
  State<AssignmentHistoryScreen> createState() =>
      _AssignmentHistoryScreenState();
}

class _AssignmentHistoryScreenState
    extends State<AssignmentHistoryScreen> {
  final DriverAssignmentRepository _assignmentRepository =
      DriverAssignmentRepository();

  final DriverService _driverService =
      DriverService();

  bool _loading = true;

  List<_AssignmentHistoryItem> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final assignments =
        await _assignmentRepository.getAllAssignments();

    final vehicleAssignments = assignments
        .where((a) => a.vehicleId == widget.vehicleId)
        .toList();

    final items = <_AssignmentHistoryItem>[];

    for (final assignment in vehicleAssignments) {
      final Driver? driver =
          await _driverService.getDriverById(
        assignment.driverId,
      );

      items.add(
        _AssignmentHistoryItem(
          assignment: assignment,
          driver: driver,
        ),
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _history = items;
      _loading = false;
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Current';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment History'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _history.isEmpty
              ? const Center(
                  child: Text(
                    'No assignment history.',
                  ),
                )
              : ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(
                          item.driver?.fullName ??
                              'Unknown Driver',
                        ),
                        subtitle: Text(
                          '${_formatDate(item.assignment.assignedFrom)}'
                          ' → '
                          '${_formatDate(item.assignment.assignedTo)}',
                        ),
                        trailing: item.assignment.active
                            ? const Chip(
                                label: Text('Current'),
                              )
                            : const Chip(
                                label: Text('Previous'),
                              ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _AssignmentHistoryItem {
  const _AssignmentHistoryItem({
    required this.assignment,
    required this.driver,
  });

  final DriverVehicleAssignment assignment;

  final Driver? driver;
}