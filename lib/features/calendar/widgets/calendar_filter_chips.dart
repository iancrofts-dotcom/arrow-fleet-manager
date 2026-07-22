import 'package:flutter/material.dart';

import '../models/calendar_filter.dart';

class CalendarFilterChips extends StatelessWidget {
  const CalendarFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CalendarFilter selected;
  final ValueChanged<CalendarFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: CalendarFilter.values.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = CalendarFilter.values[index];

          return FilterChip(
            label: Text(filter.label),
            selected: filter == selected,
            onSelected: (_) => onSelected(filter),
          );
        },
      ),
    );
  }
}