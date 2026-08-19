import 'package:flutter/material.dart';

import '../../auth/services/permission_service.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../models/calendar_event.dart';
import '../models/calendar_filter.dart';
import '../services/calendar_service.dart';
import '../widgets/calendar_event_list.dart';
import '../widgets/calendar_filter_chips.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarService _calendarService = CalendarService();

  late Future<List<CalendarEvent>> _eventsFuture;

  CalendarFilter _selectedFilter = CalendarFilter.all;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _loadEvents();
  }

  Future<List<CalendarEvent>> _loadEvents() {
    return _calendarService.buildEvents();
  }

  Future<void> _refresh() async {
    setState(() {
      _eventsFuture = _loadEvents();
    });

    await _eventsFuture;
  }

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.instance.canAccessCalendar) {
      return const _CalendarAccessDenied();
    }

    return AppPageScaffold(
      title: 'Fleet Calendar',
      subtitle: 'Upcoming fleet, maintenance and compliance dates.',
      actions: [IconButton(tooltip: 'Refresh calendar', onPressed: _refresh, icon: const Icon(Icons.refresh))],
      child: FutureBuilder<List<CalendarEvent>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(label: 'Loading calendar events...');
          }

          if (snapshot.hasError) {
            return AppErrorState(message: '${snapshot.error}', onRetry: _refresh);
          }

          final events = snapshot.data ?? [];

          final filteredEvents = events
              .where(_selectedFilter.matches)
              .toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionCard(
                    padding: const EdgeInsets.all(12),
                    child: CalendarFilterChips(
                      selected: _selectedFilter,
                      onSelected: (filter) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  CalendarEventList(
                    events: filteredEvents,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CalendarAccessDenied extends StatelessWidget {
  const _CalendarAccessDenied();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Access Denied')),
      body: const Center(
        child: Text('You do not have permission to view the fleet calendar.'),
      ),
    );
  }
}
