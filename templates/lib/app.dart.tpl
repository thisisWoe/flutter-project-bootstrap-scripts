import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:__PROJECT_NAME__/core/bindings/core_bindings.dart';
import 'package:__PROJECT_NAME__/core/config/app_config.dart';
import 'package:__PROJECT_NAME__/core/styles/app_base_theme.dart';
import 'package:__PROJECT_NAME__/core/view/controllers/theme_controller.dart';
import 'package:__PROJECT_NAME__/l10n/app_localizations.dart';

Future<void> bootstrapApp({required AppConfig config}) async {
  final preferences = await SharedPreferences.getInstance();
  CoreBindings(config: config, preferences: preferences).dependencies();

  runApp(const __APP_CLASS_NAME__());
}

class __APP_CLASS_NAME__ extends StatelessWidget {
  const __APP_CLASS_NAME__({super.key});

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
