import 'package:flutter/material.dart';

import '../../assignments/repositories/assignment_repository.dart';

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
  final AssignmentRepository _repository =
      AssignmentRepository.instance;

  bool _loading = true;

  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history =
        await _repository.getVehicleAssignmentHistory(
      widget.vehicleId,
    );

    if (!mounted) return;

    setState(() {
      _history = history;
      _loading = false;
    });
  }

  String _formatDate(int? timestamp) {
    if (timestamp == null) {
      return 'Current';
    }

    final date = DateTime.fromMillisecondsSinceEpoch(
      timestamp,
    );

    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Assignment History',
        ),
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
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

                    final firstName =
                        item['first_name'] as String? ??
                            '';

                    final lastName =
                        item['last_name'] as String? ??
                            '';

                    final active =
                        (item['active'] ?? 0) == 1;

                    return Card(
                      margin:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(
                          '$firstName $lastName',
                        ),
                        subtitle: Text(
                          '${_formatDate(item['assigned_from'] as int?)}'
                          ' → '
                          '${_formatDate(item['assigned_to'] as int?)}',
                        ),
                        trailing: Chip(
                          label: Text(
                            active
                                ? 'Current'
                                : 'Previous',
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}