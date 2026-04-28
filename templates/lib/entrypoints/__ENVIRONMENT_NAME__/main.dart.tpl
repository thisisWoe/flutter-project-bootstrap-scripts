import 'package:flutter/material.dart';
import 'package:__PROJECT_NAME__/app.dart';
import 'package:__PROJECT_NAME__/core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config = AppConfig(
    environment: '__ENVIRONMENT_NAME__',
    displayName: '__APP_DISPLAY_NAME__',
    baseUrl: '',
    routerShape: '__ROUTER_SHAPE__',
  );
  await bootstrapApp(config: config);
}
