import 'package:flutter/material.dart';
import 'package:flutter_launcher/app.dart';
import 'package:flutter_launcher/core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config = AppConfig(
    environment: 'dev',
    displayName: 'Flutter Launcer',
    baseUrl: 'http://localhost:8080',
    routerShape: 'root',
  );
  await bootstrapApp(config: config);
}
