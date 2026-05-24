import 'dart:ffi' show DynamicLibrary;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import 'app.dart';
import 'client/shared_pref_client.dart';
import 'utils/platform_helper.dart';
import 'utils/window_config.dart';

final myLogger = Logger();

Future<void> main() async {
  if (Platform.isWindows || Platform.isLinux) {
    if (Platform.isWindows) {
      // Load sqlite3.dll from the executable directory (copied from vendor/ at build time)
      open.overrideFor(OperatingSystem.windows, () {
        return DynamicLibrary.open('sqlite3.dll');
      });
      sqlite3.openInMemory().dispose();
    } else {
      sqfliteFfiInit();
    }

    // Change the default factory
    databaseFactory = databaseFactoryFfi;
  }
  WidgetsFlutterBinding.ensureInitialized();

  if (isDesktop) {
    await windowManager.ensureInitialized();
  }

  await SharedPreferenceClient.init();

  if (isDesktop) {
    final windowConfig = await WindowConfig.load();
    final isMaximized = await WindowConfig.loadIsMaximized();

    final double? left = windowConfig?['left'];
    final double? top = windowConfig?['top'];
    final double? width = windowConfig?['width'];
    final double? height = windowConfig?['height'];

    final hasPosition = left != null && top != null;
    final hasSize = width != null && height != null;

    final windowSize = hasSize ? Size(width, height) : const Size(900, 700);

    final windowOptions = WindowOptions(
      size: windowSize,
      center: !hasPosition,
      minimumSize: const Size(400, 300),
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (isMaximized) {
        await windowManager.maximize();
      } else if (left != null && top != null && width != null && height != null) {
        final restored = Rect.fromLTWH(left, top, width, height);
        if (await WindowConfig.isOnScreen(restored)) {
          await windowManager.setBounds(restored);
        }
      }

      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const ProviderScope(child: MyApp()));
}
