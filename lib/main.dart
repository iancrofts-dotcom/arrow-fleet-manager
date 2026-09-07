import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_bootstrap.dart';
import 'platform/platform_runtime.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  PlatformRuntime.initializeLocalDatabase();

  await AppBootstrap.initialize();

  runApp(const ArrowFleetManagerApp());
}
