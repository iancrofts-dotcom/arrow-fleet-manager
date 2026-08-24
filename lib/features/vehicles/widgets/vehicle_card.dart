import 'package:flutter/material.dart';

import '../../compliance/services/compliance_service.dart';
import '../../compliance/widgets/compliance_status_chip.dart';
import '../../../shared/status_badge.dart';

import '../models/vehicle.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback? onTap;

  const VehicleCard({super.key, required this.vehicle, this.onTap});

  @override
  Widget build(BuildContext context) {
    const complianceService = ComplianceService();

    final motStatus = complianceService.getStatus(vehicle.motExpiry);

    final serviceStatus = complianceService.getStatus(vehicle.serviceDue);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      vehicle.fleetNumber,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.registration,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text("${vehicle.make} ${vehicle.model}"),
                      ],
                    ),
                  ),

                  vehicle.active
                      ? StatusBadge.success('Active')
                      : StatusBadge.neutral('Inactive'),

                  const SizedBox(width: 8),

                  const Icon(Icons.more_vert),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  const SizedBox(
                    width: 80,
                    child: Text(
                      "MOT",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ComplianceStatusChip(status: motStatus),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  const SizedBox(
                    width: 80,
                    child: Text(
                      "Service",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ComplianceStatusChip(status: serviceStatus),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
