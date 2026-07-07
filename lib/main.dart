import 'package:flutter/material.dart';
import 'screens/dashboard/dashboard_screen.dart';

void main() {
  runApp(const ArrowFleetManager());
}

class ArrowFleetManager extends StatelessWidget {
  const ArrowFleetManager({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Arrow Fleet Manager",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const DashboardScreen(),
    );
  }
}