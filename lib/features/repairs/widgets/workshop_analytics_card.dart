import 'package:flutter/material.dart';

import '../models/repair_trend.dart';

class WorkshopAnalyticsCard extends StatelessWidget {
  const WorkshopAnalyticsCard({
    super.key,
    required this.trends,
  });

  final List<RepairTrend> trends;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Repair Trends',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 16),

            if (trends.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No repair trend data available.',
                  ),
                ),
              )
            else
              Column(
                children: trends.map((trend) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text(
                            trend.period,
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),

                        Expanded(
                          child: LinearProgressIndicator(
                            value: trend.opened == 0
                                ? 0
                                : trend.completed /
                                    trend.opened,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Text(
                          '${trend.completed}/${trend.opened}',
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}