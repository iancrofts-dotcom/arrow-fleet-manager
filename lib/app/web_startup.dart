import 'package:flutter/material.dart';

import '../shared/widgets/fleetiq_brand.dart';
import 'constants.dart';
import 'theme.dart';

class WebStartup extends StatefulWidget {
  const WebStartup({
    super.key,
    required this.initialize,
    required this.application,
  });

  final Future<void> Function() initialize;
  final Widget application;

  @override
  State<WebStartup> createState() => _WebStartupState();
}

class _WebStartupState extends State<WebStartup> {
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = widget.initialize();
  }

  void _retry() {
    final initialization = widget.initialize();
    setState(() {
      _initialization = initialization;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return widget.application;
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppConstants.appName,
          theme: AppTheme.lightTheme,
          home: Scaffold(
            backgroundColor: AppConstants.appBackgroundColor,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FleetIqBrand.wide(height: 72),
                      const SizedBox(height: 12),
                      const Text(AppConstants.tagline),
                      const SizedBox(height: 28),
                      if (snapshot.hasError) ...[
                        const Text(
                          'FleetIQ could not start. Check your connection and try again.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _retry,
                          child: const Text('Try again'),
                        ),
                      ] else
                        const CircularProgressIndicator(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
