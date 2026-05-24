import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
import 'package:window_manager/window_manager.dart';

import 'deep_link_handler.dart';
import 'repositories/database.dart';
import 'screens/home/home_page.dart';
import 'screens/home/home_view_controller.dart';
import 'screens/nsy_list/nsy_choice.dart';
import 'utils/platform_helper.dart';
import 'utils/window_config.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => MyAppState();
}

class MyAppState extends ConsumerState<MyApp> with WindowListener {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _appLinks = AppLinks();
  StreamSubscription<String>? _mobilelinkSubscription;
  StreamSubscription<Uri>? _desktoplinkSubscription;

  @override
  void initState() {
    super.initState();
    if (isMobile) {
      initMobileDeepLinks();
    }
    if (isDesktop) {
      windowManager.addListener(this);
      windowManager.setPreventClose(true);
      _handleIncomingLinks();
      _handleInitialUri();
    }
  }

  @override
  void dispose() {
    _mobilelinkSubscription?.cancel();
    _desktoplinkSubscription?.cancel();
    if (isDesktop) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowClose() async {
    await windowManager.hide();
    final isMaximized = await windowManager.isMaximized();

    if (!isMaximized) {
      final position = await windowManager.getPosition();
      final size = await windowManager.getSize();
      await WindowConfig.save(
        left: position.dx,
        top: position.dy,
        width: size.width,
        height: size.height,
        isMaximized: false,
      );
    } else {
      await WindowConfig.saveMaximized();
    }

    await DatabaseHelper().close();
    await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attha Nissaya',
      theme: ThemeData(primarySwatch: Colors.orange, useMaterial3: false),
      darkTheme: ThemeData.dark(useMaterial3: false),
      themeMode: themeMode,
      navigatorKey: _navigatorKey,
      home: const Home(),
    );
  }

  Future<void> initMobileDeepLinks() async {
    final mobileDeepLink = DeepLinkHandler();
    _mobilelinkSubscription = mobileDeepLink.state.listen((uri) {
      debugPrint('onAppLink: $uri');
      openMobileAppLink(uri);
    });
  }

  /// Handle incoming links - the ones that the app will recieve from the OS
  /// while already started.
  void _handleIncomingLinks() {
    if (!kIsWeb) {
      _desktoplinkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
        debugPrint('onAppLink: $uri');
        openDesktopAppLink(uri);
      }, onError: (Object err) {});
    }
  }

  Future<void> _handleInitialUri() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        debugPrint('onAppLink: $uri');
        openDesktopAppLink(uri);
      }
    } on PlatformException {
      debugPrint('falied to get initial uri');
    }
  }

  void openMobileAppLink(String url) {
    final paliBookId = parseBookId(url);
    final pageNumber = parsePageNumber(url);
    if (paliBookId != null && pageNumber != null) {
      final route = nsyChoiceRoute(
        paliBookId: paliBookId,
        pageNumber: int.parse(pageNumber),
      );
      _navigatorKey.currentState
          ?.pushAndRemoveUntil(route, (Route<dynamic> route) => false);
    }
  }

  void openDesktopAppLink(Uri uri) {
    final url = uri.toString();
    final paliBookId = parseBookId(url);
    final pageNumber = parsePageNumber(url);
    debugPrint(paliBookId);
    debugPrint(pageNumber);
    if (paliBookId != null && pageNumber != null) {
      // Todo: extract book name from db
      final route = nsyChoiceRoute(
        paliBookId: paliBookId,
        pageNumber: int.parse(pageNumber),
      );

      _navigatorKey.currentState
          ?.pushAndRemoveUntil(route, (Route<dynamic> route) => false);
    }
  }

  MaterialPageRoute nsyChoiceRoute(
      {required String paliBookId,
      required int pageNumber}) {
    return MaterialPageRoute(
      builder: (_) => NsyChoice(
        paliBookID: paliBookId,
        paliBookPageNumber: pageNumber,
        isOpenFromDeepLink: true,
      ),
    );
  }

  String? parseBookId(String url) {
    RegExp regexId = RegExp(r'\w+_\w+_\d+(_\d+)?');
    final matchId = regexId.firstMatch(url);
    return matchId?.group(0);
  }

  String? parsePageNumber(String url) {
    RegExp regexPage = RegExp(r'\d+$');
    final matchPage = regexPage.firstMatch(url);
    return matchPage?.group(0);
  }
}
