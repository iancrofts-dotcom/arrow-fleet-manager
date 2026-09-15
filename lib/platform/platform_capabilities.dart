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

  bool get isCentralMode => backendMode == BackendMode.supabase;
  bool get isCentralWeb => isWeb && isCentralMode;
  bool get supportsApplicationConfiguration =>
      !isWeb || backendMode == BackendMode.supabase;
  bool get supportsLocalData => !isWeb && !isCentralMode;

  bool routeAvailable(String route) {
    if (!isCentralMode) return true;
    final common =
        route == '/dashboard' ||
        route == '/vehicles' ||
        route == '/drivers' ||
        route == '/users' ||
        route == '/calendar' ||
        route == '/compliance' ||
        route == '/workshop' ||
        route == '/documents' ||
        route == '/reports' ||
        route == '/driver/vehicle' ||
        route == '/driver/inspection' ||
        route == '/driver/compliance' ||
        route == '/driver/documents' ||
        route == '/driver/profile';
    return common;
  }
}
