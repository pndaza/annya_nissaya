import 'dart:ui';

import 'package:screen_retriever/screen_retriever.dart';

import '../client/shared_pref_client.dart';

class WindowConfig {
  WindowConfig._();

  static const _keyLeft = 'window_left';
  static const _keyTop = 'window_top';
  static const _keyWidth = 'window_width';
  static const _keyHeight = 'window_height';
  static const _keyIsMaximized = 'window_is_maximized';

  static Future<Map<String, double>?> load() async {
    final prefs = SharedPreferenceClient.instance;
    final left = prefs.getDouble(_keyLeft);
    final top = prefs.getDouble(_keyTop);
    final width = prefs.getDouble(_keyWidth);
    final height = prefs.getDouble(_keyHeight);

    if (left == null || top == null || width == null || height == null) {
      return null;
    }

    return {'left': left, 'top': top, 'width': width, 'height': height};
  }

  static Future<bool> loadIsMaximized() async {
    return SharedPreferenceClient.instance.getBool(_keyIsMaximized) ?? false;
  }

  static Future<void> save({
    required double left,
    required double top,
    required double width,
    required double height,
    required bool isMaximized,
  }) async {
    final prefs = SharedPreferenceClient.instance;
    await prefs.setDouble(_keyLeft, left);
    await prefs.setDouble(_keyTop, top);
    await prefs.setDouble(_keyWidth, width);
    await prefs.setDouble(_keyHeight, height);
    await prefs.setBool(_keyIsMaximized, isMaximized);
  }

  static Future<void> saveMaximized() async {
    await SharedPreferenceClient.instance.setBool(_keyIsMaximized, true);
  }

  static Future<bool> isOnScreen(Rect rect) async {
    final displays = await screenRetriever.getAllDisplays();
    for (final display in displays) {
      if (display.visiblePosition != null && display.visibleSize != null) {
        final visibleRect = Rect.fromLTWH(
          display.visiblePosition!.dx,
          display.visiblePosition!.dy,
          display.visibleSize!.width,
          display.visibleSize!.height,
        );
        if (visibleRect.overlaps(rect)) {
          return true;
        }
      }
    }
    return false;
  }
}
