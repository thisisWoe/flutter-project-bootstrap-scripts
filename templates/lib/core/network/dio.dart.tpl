import 'package:dio/dio.dart';
import 'package:__PROJECT_NAME__/core/config/app_config.dart';

Dio provideDio({
  AppConfig? appConfig,
  List<Interceptor>? interceptors,
}) {
  final baseUrl = appConfig?.baseUrl ?? '';
  final options = BaseOptions(
    baseUrl: baseUrl.isEmpty ? 'http://localhost:8080/api' : '$baseUrl/api',
    headers: {'Accept': 'application/json'},
    contentType: Headers.jsonContentType,
    connectTimeout: const Duration(milliseconds: 130000),
    receiveTimeout: const Duration(milliseconds: 130000),
  );
  final dio = Dio(options);

  if (interceptors != null) {
    for (final interceptor in interceptors) {
      dio.interceptors.add(interceptor);
    }
  }
  return dio;
}
