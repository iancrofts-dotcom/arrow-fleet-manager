import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class PlatformRuntime {
  const PlatformRuntime._();

  static const supportsLocalData = true;

  static void initializeLocalDatabase() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }
}
