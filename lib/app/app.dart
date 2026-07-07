import 'package:flutter/material.dart';

import '../features/dashboard/dashboard_screen.dart';
import 'constants.dart';
import 'theme.dart';

class ArrowFleetManagerApp extends StatelessWidget {
  const ArrowFleetManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: AppConstants.appName,

      theme: AppTheme.lightTheme,

      home: const DashboardScreen(),
    );
  }
}