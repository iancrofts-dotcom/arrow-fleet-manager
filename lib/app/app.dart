import 'package:flutter/material.dart';

import 'constants.dart';
import 'router.dart';
import 'theme.dart';
import '../features/auth/services/auth_service.dart';
import '../features/auth/widgets/session_activity_boundary.dart';
import '../shared/widgets/app_shell.dart';

class ArrowFleetManagerApp extends StatefulWidget {
  const ArrowFleetManagerApp({super.key});

  @override
  State<ArrowFleetManagerApp> createState() => _ArrowFleetManagerAppState();
}

class _ArrowFleetManagerAppState extends State<ArrowFleetManagerApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _currentRoute = ValueNotifier<String>(AppRouter.dashboard);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,

      initialRoute: AppRouter.root,

      routes: AppRouter.routes,
      navigatorObservers: [_AppRouteObserver(_currentRoute)],

      onGenerateRoute: AppRouter.onGenerateRoute,

      builder: (context, child) => AnimatedBuilder(
        animation: AuthService.instance,
        builder: (context, _) => SessionActivityBoundary(
          navigatorKey: _navigatorKey,
          authService: AuthService.instance,
          child: AppShell(
            navigatorKey: _navigatorKey,
            currentRoute: _currentRoute,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _AppRouteObserver extends NavigatorObserver {
  _AppRouteObserver(this.currentRoute);

  final ValueNotifier<String> currentRoute;

  void _update(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null && name != AppRouter.root) currentRoute.value = name;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _update(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _update(newRoute);
}
