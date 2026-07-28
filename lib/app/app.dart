import 'package:flutter/material.dart';

import 'constants.dart';
import 'router.dart';
import 'theme.dart';

class ArrowFleetManagerApp extends StatelessWidget {
  const ArrowFleetManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,

      // Navigation
      initialRoute: AppRouter.root,
      routes: AppRouter.routes,
      onGenerateRoute: AppRouter.onGenerateRoute,

      // Prevent duplicate navigation banner
      home: null,
    );
  }
}