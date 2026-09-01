import 'package:flutter/material.dart';

import '../../../shared/widgets/app_page_scaffold.dart';
import '../models/calendar_event.dart';
import '../models/calendar_group.dart';
import 'calendar_event_card.dart';

class CalendarEventList extends StatelessWidget {
  const CalendarEventList({super.key, required this.events, this.onEventTap});

  final List<CalendarEvent> events;
  final ValueChanged<CalendarEvent>? onEventTap;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const AppEmptyState(
        icon: Icons.event_available_outlined,
        title: 'No upcoming MOT or service events.',
        message: 'There are no calendar events for the selected filter.',
      );
    }

    final grouped = events.grouped();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: CalendarGroup.values
          .map((group) => _buildSection(context, group, grouped[group]!))
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

    final colour = _colour(group);

    return SectionCard(
      margin: const EdgeInsets.only(bottom: 24),
      title: group.title,
      subtitle: '${events.length} event${events.length == 1 ? '' : 's'}',
      trailing: CircleAvatar(
        radius: 18,
        backgroundColor: colour.withValues(alpha: 0.12),
        child: Icon(_icon(group), color: colour, size: 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...events.map(
            (event) => CalendarEventCard(
              event: event,
              onTap: event.vehicleId == null || onEventTap == null
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
