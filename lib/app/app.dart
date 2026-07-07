import 'package:flutter/material.dart';
import '../features/dashboard/dashboard_screen.dart';
import 'theme.dart';

class ArrowFleetManagerApp extends StatelessWidget {
  const ArrowFleetManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arrow Fleet Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DashboardScreen(),
    );
  }
}