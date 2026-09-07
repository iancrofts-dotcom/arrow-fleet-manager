import 'package:flutter/foundation.dart';

import '../config/backend_mode.dart';

class PlatformCapabilities {
  const PlatformCapabilities({required this.isWeb, required this.backendMode});

  factory PlatformCapabilities.current() => PlatformCapabilities(
    isWeb: kIsWeb,
    backendMode: BackendModeConfig.current,
  );

  final bool isWeb;
  final BackendMode backendMode;

  bool get isCentralWeb => isWeb && backendMode == BackendMode.supabase;
  bool get supportsApplicationConfiguration =>
      !isWeb || backendMode == BackendMode.supabase;
  bool get supportsLocalData => !isWeb;

  bool routeAvailable(String route) =>
      !isCentralWeb || route == '/dashboard' || route == '/vehicles';
}
