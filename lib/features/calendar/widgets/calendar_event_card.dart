import 'package:flutter/material.dart';

import '../models/calendar_event.dart';

class CalendarEventCard extends StatelessWidget {
  const CalendarEventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  final CalendarEvent event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final daysRemaining = DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
    ).difference(
      DateTime(
        today.year,
        today.month,
        today.day,
      ),
    ).inDays;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: event.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  event.icon,
                  color: event.color,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      event.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusChip(
                          color: event.color,
                          text: _status(daysRemaining),
                        ),
                        _DateChip(
                          date: event.date,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _status(int days) {
    if (days < 0) {
      return 'Overdue by ${days.abs()} day${days.abs() == 1 ? '' : 's'}';
    }

    if (days == 0) {
      return 'Due Today';
    }

    if (days == 1) {
      return 'Due Tomorrow';
    }

    return '$days days remaining';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.color,
    required this.text,
  });

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        Icons.schedule,
        size: 18,
        color: color,
      ),
      label: Text(text),
      backgroundColor: color.withValues(alpha: 0.10),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
  });

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(
        Icons.calendar_today,
        size: 18,
      ),
      label: Text(
        '${date.day}/${date.month}/${date.year}',
      ),
    );
  }
}