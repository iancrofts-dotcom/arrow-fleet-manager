import 'package:flutter/material.dart';
import '../utils/calendar_date_formatter.dart';
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
    final theme = Theme.of(context);

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
      margin: const EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 5,
                color: event.color,
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: event.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          event.icon,
                          color: event.color,
                          size: 30,
                        ),
                      ),

                      const SizedBox(width: 18),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              event.subtitle,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),

                            const SizedBox(height: 18),

                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 18,
                                  color: event.color,
                                ),

                                const SizedBox(width: 6),

                                Expanded(
                                  child: Text(
                                    _status(daysRemaining),
                                    style: theme
                                        .textTheme.bodySmall
                                        ?.copyWith(
                                      color: event.color,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                ),

                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: theme.colorScheme.outline,
                                ),

                                const SizedBox(width: 6),

                                Text(
                                 CalendarDateFormatter.format(event.date),
                                  style: theme
                                      .textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.outline,
                      ),
                    ],
                  ),
                ),
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

    if (days <= 7) {
      return 'Due this week';
    }

    return '$days days remaining';
  }

 }