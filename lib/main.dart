import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'app/app.dart';
import 'app/app_bootstrap.dart';
import 'app/web_startup.dart';
import 'platform/platform_runtime.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    runApp(
      WebStartup(
        initialize: AppBootstrap.initialize,
        application: const ArrowFleetManagerApp(),
      ),
    );
    return;
  }

  PlatformRuntime.initializeLocalDatabase();

  await AppBootstrap.initialize();

  runApp(const ArrowFleetManagerApp());
}
