import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import '../models/calendar_group.dart';
import 'calendar_event_card.dart';

class CalendarEventList extends StatelessWidget {
  const CalendarEventList({
    super.key,
    required this.events,
    this.onEventTap,
  });

  final List<CalendarEvent> events;
  final ValueChanged<CalendarEvent>? onEventTap;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No upcoming fleet events.',
            ),
          ),
        ),
      );
    }

    final grouped = events.grouped();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: CalendarGroup.values
          .map(
            (group) => _buildSection(
              context,
              group,
              grouped[group]!,
            ),
          )
          .whereType<Widget>()
          .toList(),
    );
  }

  Widget? _buildSection(
    BuildContext context,
    CalendarGroup group,
    List<CalendarEvent> events,
  ) {
    if (events.isEmpty) {
      return null;
    }

    final theme = Theme.of(context);
    final colour = _colour(group);

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colour.withValues(alpha: 0.12),
                child: Icon(
                  _icon(group),
                  color: colour,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.title,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${events.length} event${events.length == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(
                        color: theme
                            .colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Divider(
            color: colour.withValues(alpha: 0.25),
            thickness: 1,
          ),

          const SizedBox(height: 8),

          ...events.map(
            (event) => CalendarEventCard(
              event: event,
              onTap: onEventTap == null
                  ? null
                  : () => onEventTap!(event),
            ),
          ),
        ],
      ),
    );
  }

  IconData _icon(CalendarGroup group) {
    switch (group) {
      case CalendarGroup.overdue:
        return Icons.warning_amber_rounded;

      case CalendarGroup.thisWeek:
        return Icons.schedule;

      case CalendarGroup.next30Days:
        return Icons.event;

      case CalendarGroup.future:
        return Icons.calendar_month;
    }
  }

  Color _colour(CalendarGroup group) {
    switch (group) {
      case CalendarGroup.overdue:
        return Colors.red;

      case CalendarGroup.thisWeek:
        return Colors.orange;

      case CalendarGroup.next30Days:
        return Colors.amber;

      case CalendarGroup.future:
        return Colors.blue;
    }
  }
}