import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:__PROJECT_NAME__/core/config/app_config.dart';
import 'package:__PROJECT_NAME__/core/routing/routes.dart' as root_routes;
import 'package:__PROJECT_NAME__/core/routing/shell_routes.dart' as shell_routes;
import 'package:__PROJECT_NAME__/core/view/controllers/theme_controller.dart';
import 'package:__PROJECT_NAME__/core/view/data/repo_impl/theme_repository_shared_prefs_impl.dart';
import 'package:__PROJECT_NAME__/core/view/domain/repositories/theme_repository.dart';
import 'package:__PROJECT_NAME__/core/view/domain/use_cases/get_theme_mode.dart';
import 'package:__PROJECT_NAME__/core/view/domain/use_cases/set_theme_mode.dart';
import 'package:__PROJECT_NAME__/core/network/dio.dart';

class CoreBindings implements Bindings {
  const CoreBindings({
    required this.config,
    required this.preferences,
  });

  final AppConfig config;
  final SharedPreferences preferences;

  @override
  void dependencies() {
    Get.put<AppConfig>(config, permanent: true);
    Get.put<SharedPreferences>(preferences, permanent: true);
    Get.put<Dio>(provideDio(appConfig: config), permanent: true);
    Get.put<ThemeRepository>(
      ThemeRepositorySharedPrefsImpl(preferences),
      permanent: true,
    );
    Get.put<GetThemeModeUseCase>(
      GetThemeModeUseCase(Get.find<ThemeRepository>()),
      permanent: true,
    );
    Get.put<SetThemeModeUseCase>(
      SetThemeModeUseCase(Get.find<ThemeRepository>()),
      permanent: true,
    );
    Get.put<ThemeController>(
      ThemeController(
        getThemeMode: Get.find<GetThemeModeUseCase>(),
        setThemeModeUseCase: Get.find<SetThemeModeUseCase>(),
      ),
      permanent: true,
    );

    final router = config.routerShape == 'shell'
        ? shell_routes.buildShellRouter()
        : root_routes.buildRootRouter();
    Get.put<GoRouter>(router, permanent: true);
  }
}
