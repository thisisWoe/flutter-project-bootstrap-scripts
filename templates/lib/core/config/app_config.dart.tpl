import 'package:flutter/foundation.dart';

@immutable
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.displayName,
    required this.baseUrl,
    required this.routerShape,
  });

  final String environment;
  final String displayName;
  final String baseUrl;
  final String routerShape;
}
