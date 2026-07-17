import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import '../models/calendar_group.dart';
import 'calendar_event_card.dart';

class CalendarEventList extends StatelessWidget {
  const CalendarEventList({
    super.key,
    required this.events,
  });

  final List<CalendarEvent> events;

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

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _icon(group),
                color: _color(group),
              ),
              const SizedBox(width: 8),
              Text(
                '${group.title} (${events.length})',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ...events.map(
            (event) => CalendarEventCard(
              event: event,
            ),
          ),
        ],
      ),
    );
  }

  IconData _icon(CalendarGroup group) {
    switch (group) {
      case CalendarGroup.overdue:
        return Icons.warning;

      case CalendarGroup.thisWeek:
        return Icons.schedule;

      case CalendarGroup.next30Days:
        return Icons.event;

      case CalendarGroup.future:
        return Icons.calendar_month;
    }
  }

  Color _color(CalendarGroup group) {
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