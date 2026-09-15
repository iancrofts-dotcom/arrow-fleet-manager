import 'package:flutter/material.dart';

import '../../auth/services/permission_service.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../models/calendar_event.dart';
import '../models/calendar_filter.dart';
import '../services/calendar_event_navigator.dart';
import '../services/calendar_service.dart';
import '../widgets/calendar_event_list.dart';
import '../widgets/calendar_filter_chips.dart';

typedef CalendarEventsLoader = Future<List<CalendarEvent>> Function();
typedef CalendarEventOpener =
    Future<void> Function(BuildContext context, CalendarEvent event);

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, this.loadEvents, this.onOpenEvent});

  final CalendarEventsLoader? loadEvents;
  final CalendarEventOpener? onOpenEvent;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarService? _calendarService;
  CalendarEventNavigator? _eventNavigator;

  late Future<List<CalendarEvent>> _eventsFuture;

  CalendarFilter _selectedFilter = CalendarFilter.all;

  @override
  void initState() {
    super.initState();
    if (widget.loadEvents == null) {
      _calendarService = CalendarService();
      _eventNavigator = CalendarEventNavigator();
    }
    _eventsFuture = _loadEvents();
  }

  Future<List<CalendarEvent>> _loadEvents() {
    return widget.loadEvents?.call() ?? _calendarService!.buildEvents();
  }

  Future<void> _refresh() async {
    setState(() {
      _eventsFuture = _loadEvents();
    });

    await _eventsFuture;
  }

  Future<void> _openEvent(CalendarEvent event) async {
    if (widget.onOpenEvent != null) {
      await widget.onOpenEvent!(context, event);
      if (mounted) await _refresh();
      return;
    }
    final opened = await _eventNavigator!.openDetails(context, event);
    if (!opened || !mounted) return;
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.instance.canAccessCalendar) {
      return const _CalendarAccessDenied();
    }

    return AppPageScaffold(
      title: 'Calendar',
      subtitle: 'Upcoming fleet, maintenance and compliance dates.',
      child: FutureBuilder<List<CalendarEvent>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(label: 'Loading calendar events...');
          }

          if (snapshot.hasError) {
            return AppErrorState(
              message: 'Unable to load calendar events.',
              onRetry: _refresh,
            );
          }

          final events = snapshot.data ?? [];

          final filteredEvents = events.where(_selectedFilter.matches).toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionCard(
                    title: 'Event filters',
                    subtitle: 'Filter the existing calendar timeline.',
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
                    onEventTap: _openEvent,
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
