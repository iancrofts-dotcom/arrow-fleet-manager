import 'package:flutter/material.dart';

import '../features/auth/widgets/auth_gate.dart';
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
      home: const AuthGate(),
    );
  }
}