import 'package:flutter/material.dart';

import '../../compliance/services/compliance_service.dart';
import '../../compliance/widgets/compliance_status_chip.dart';

import '../models/vehicle.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback? onTap;

  const VehicleCard({
    super.key,
    required this.vehicle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const complianceService = ComplianceService();

    final motStatus =
        complianceService.getStatus(vehicle.motExpiry);

    final serviceStatus =
        complianceService.getStatus(vehicle.serviceDue);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Text(vehicle.fleetNumber),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.registration,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${vehicle.make} ${vehicle.model}",
                        ),
                      ],
                    ),
                  ),

                  Chip(
                    label: Text(
                      vehicle.active
                          ? 'Active'
                          : 'Inactive',
                    ),
                    backgroundColor: vehicle.active
                        ? Colors.green.shade100
                        : Colors.grey.shade300,
                    visualDensity:
                        VisualDensity.compact,
                  ),

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
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                  ComplianceStatusChip(
                    status: motStatus,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  const SizedBox(
                    width: 80,
                    child: Text(
                      "Service",
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                  ComplianceStatusChip(
                    status: serviceStatus,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}