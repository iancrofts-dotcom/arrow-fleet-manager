import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import '../services/calendar_service.dart';
import '../widgets/calendar_event_list.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarService _calendarService = CalendarService();

  late Future<List<CalendarEvent>> _eventsFuture;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Calendar'),
      ),
      body: FutureBuilder<List<CalendarEvent>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading calendar:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final events = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: CalendarEventList(
                events: events,
              ),
            ),
          );
        },
      ),
    );
  }
}