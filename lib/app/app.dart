import 'package:flutter/material.dart';

import 'constants.dart';
import 'router.dart';
import 'theme.dart';
import '../features/auth/services/auth_service.dart';
import '../features/auth/widgets/session_activity_boundary.dart';

class ArrowFleetManagerApp extends StatefulWidget {
  const ArrowFleetManagerApp({super.key});

  @override
  State<ArrowFleetManagerApp> createState() => _ArrowFleetManagerAppState();
}

class _ArrowFleetManagerAppState extends State<ArrowFleetManagerApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,

      initialRoute: AppRouter.root,

      routes: AppRouter.routes,

      onGenerateRoute: AppRouter.onGenerateRoute,

      builder: (context, child) => SessionActivityBoundary(
        navigatorKey: _navigatorKey,
        authService: AuthService.instance,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
