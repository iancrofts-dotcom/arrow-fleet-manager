import 'package:flutter/material.dart';

import '../models/calendar_event.dart';

class CalendarEventList extends StatelessWidget {
  final List<CalendarEvent> events;

  const CalendarEventList({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No upcoming fleet events.',
            ),
          ),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: events.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1),
        itemBuilder: (context, index) {
          final event = events[index];

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: event.color.withValues(alpha: 0.15),
              child: Icon(
                event.icon,
                color: event.color,
              ),
            ),
            title: Text(event.title),
            subtitle: Text(event.subtitle),
            trailing: Text(
              _formatDate(event.date),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}