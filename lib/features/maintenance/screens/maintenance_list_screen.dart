import 'package:flutter/material.dart';

import '../models/maintenance_record.dart';
import '../services/maintenance_service.dart';
import '../widgets/maintenance_record_card.dart';
import 'add_maintenance_screen.dart';
import 'edit_maintenance_screen.dart';

class MaintenanceListScreen extends StatefulWidget {
  const MaintenanceListScreen({
    super.key,
    required this.vehicleId,
  });

  final int vehicleId;

  @override
  State<MaintenanceListScreen> createState() =>
      _MaintenanceListScreenState();
}

class _MaintenanceListScreenState
    extends State<MaintenanceListScreen> {
  final MaintenanceService _service =
      MaintenanceService();

  late Future<List<MaintenanceRecord>> _future;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() {
    _future = _service.getForVehicle(
      widget.vehicleId,
    );
  }

  Future<void> _refresh() async {
    setState(_loadRecords);
    await _future;
  }

  Future<void> _addMaintenance() async {
    final refresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddMaintenanceScreen(
          vehicleId: widget.vehicleId,
        ),
      ),
    );

    if (refresh == true && mounted) {
      setState(_loadRecords);
    }
  }

  Future<void> _editMaintenance(
    MaintenanceRecord record,
  ) async {
    final refresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditMaintenanceScreen(
          record: record,
        ),
      ),
    );

    if (refresh == true && mounted) {
      setState(_loadRecords);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance'),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _addMaintenance,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: FutureBuilder<List<MaintenanceRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
              ),
            );
          }

          final records =
              snapshot.data ?? [];

          if (records.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 150),
                  Center(
                    child: Text(
                      'No maintenance scheduled.',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: records.length,
              itemBuilder:
                  (context, index) {
                final record =
                    records[index];

                return MaintenanceRecordCard(
                  record: record,
                  onTap: () =>
                      _editMaintenance(
                    record,
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