import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_launcher/core/bindings/core_bindings.dart';
import 'package:flutter_launcher/core/config/app_config.dart';
import 'package:flutter_launcher/core/styles/app_base_theme.dart';
import 'package:flutter_launcher/core/view/controllers/theme_controller.dart';
import 'package:flutter_launcher/l10n/app_localizations.dart';
import 'package:window_manager/window_manager.dart';

Future<void> bootstrapApp({required AppConfig config}) async {
  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(center: true, skipTaskbar: false);

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setResizable(true);
    await windowManager.maximize();
    await windowManager.show();
    await windowManager.focus();
  });

  final preferences = await SharedPreferences.getInstance();
  preferences.clear();
  CoreBindings(config: config, preferences: preferences).dependencies();

  runApp(const FlutterLauncherApp());
}

class FlutterLauncherApp extends StatelessWidget {
  const FlutterLauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = Get.find<AppConfig>();
    final router = Get.find<GoRouter>();
    final themeController = Get.find<ThemeController>();

    return Obx(
      () => MaterialApp.router(
        title: config.displayName,
        theme: AppBaseTheme.light,
        darkTheme: AppBaseTheme.dark,
        themeMode: themeController.themeMode.value,
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
