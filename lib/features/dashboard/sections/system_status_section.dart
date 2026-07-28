import 'package:flutter/material.dart';

import '../models/system_status.dart';
import '../services/system_status_service.dart';
import '../widgets/cards/dashboard_card.dart';
import '../widgets/cards/dashboard_card_body.dart';
import '../widgets/cards/dashboard_card_header.dart';
import '../widgets/cards/status_chip.dart';

class SystemStatusSection extends StatefulWidget {
  const SystemStatusSection({super.key});

  @override
  State<SystemStatusSection> createState() => _SystemStatusSectionState();
}

class _SystemStatusSectionState extends State<SystemStatusSection> {
  final SystemStatusService _service = const SystemStatusService();

  late Future<List<SystemStatus>> _future;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  void _loadStatus() {
    _future = _service.getSystemStatus();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadStatus();
    });

    await _future;
  }

  StatusChipState _chipState(SystemServiceStatus status) {
    switch (status) {
      case SystemServiceStatus.healthy:
        return StatusChipState.healthy;

      case SystemServiceStatus.warning:
        return StatusChipState.warning;

      case SystemServiceStatus.error:
        return StatusChipState.error;

      case SystemServiceStatus.offline:
        return StatusChipState.inactive;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: FutureBuilder<List<SystemStatus>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardCardHeader(
                  title: 'System Status',
                  icon: Icons.monitor_heart,
                  trailing: IconButton(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Unable to load system status.',
                ),
              ],
            );
          }

          final services = snapshot.data ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardCardHeader(
                title: 'System Status',
                subtitle: 'Current application health',
                icon: Icons.monitor_heart,
                trailing: IconButton(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ),

              const SizedBox(height: 20),

              DashboardCardBody(
                spacing: 14,
                children: services
                    .map(
                      (service) => Row(
                        children: [
                          Expanded(
                            child: Text(
                              service.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge,
                            ),
                          ),
                          StatusChip(
                            label: service.status.name.toUpperCase(),
                            state: _chipState(service.status),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 20),

              Text(
                'Last updated: ${TimeOfDay.now().format(context)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}