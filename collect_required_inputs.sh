#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
required_input_names=(
  project_name
  app_display_name
  target_platforms
  environment_names
  router_shape
)

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

lowercase() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

sanitize_snake_case() {
  local value
  value="$(lowercase "$1")"
  value="$(printf '%s' "$value" | LC_ALL=C sed -E 's/[^[:alnum:]]+/_/g; s/^_+//; s/_+$//')"
  if [[ -z "$value" ]]; then
    value="app"
  fi
  if [[ "$value" == [0-9]* ]]; then
    value="app_$value"
  fi
  printf '%s' "$value"
}

sanitize_platform_name() {
  local value
  value="$(lowercase "$1")"
  value="$(printf '%s' "$value" | LC_ALL=C tr -cd '[:alnum:]')"
  if [[ -z "$value" ]]; then
    value="app"
  fi
  if [[ "$value" == [0-9]* ]]; then
    value="app$value"
  fi
  printf '%s' "$value"
}

pascal_case() {
  local value="$1"
  local result=""
  local part=""

  value="$(printf '%s' "$value" | LC_ALL=C sed -E 's/[^[:alnum:]]+/_/g; s/^_+//; s/_+$//')"
  IFS='_' read -r -a parts <<< "$value"
  for part in "${parts[@]}"; do
    [[ -z "$part" ]] && continue
    result+="$(printf '%s' "${part:0:1}" | tr '[:lower:]' '[:upper:]')${part:1}"
  done

  if [[ -z "$result" ]]; then
    result="App"
  fi
  if [[ "$result" == [0-9]* ]]; then
    result="App$result"
  fi

  printf '%s' "$result"
}

temp_directory_value() {
  local base_dir="${TMPDIR:-/tmp}"
  printf '%s/flutter-bootstrap-%s-%s' "$base_dir" "$$" "${RANDOM:-0}"
}

create_temp_workspace() {
  local workspace
  workspace="$(temp_directory_value)"
  mkdir -p "$workspace"
  printf '%s' "$workspace"
}

run_fvm_setup() {
  local fvm_path=""
  if ! fvm_path="$(command -v fvm 2>/dev/null)"; then
    echo "FVM check failed: fvm was not found in PATH." >&2
    echo "Install FVM first, then rerun this script." >&2
    return 1
  fi

  echo "FVM setup"
  echo "fvm found at: $fvm_path"
  echo "Running: fvm install stable"
  if ! fvm install stable; then
    echo "FVM setup failed while installing the stable Flutter SDK." >&2
    return 1
  fi

  echo "Running: fvm use stable --force --skip-pub-get"
  if ! fvm use stable --force --skip-pub-get; then
    echo "FVM setup failed while selecting the stable Flutter SDK." >&2
    return 1
  fi

  echo "Running: fvm flutter --version"
  if ! fvm flutter --version; then
    echo "FVM setup failed while verifying the Flutter SDK version." >&2
    return 1
  fi

  echo "FVM stable channel is ready."
  return 0
}

confirm_apple_rename_readiness() {
  case " $target_platforms " in
    *" ios "*|*" macos "*)
      echo "Apple rename check"
      echo "Selected platforms include iOS or macOS."
      echo "Derived Apple identifiers can be computed deterministically from the requested project name."
      ;;
    *)
      return 0
      ;;
  esac

  if [[ -z "$flutter_project_name" || -z "$platform_identifier_base" || -z "$app_display_name" ]]; then
    echo "Apple rename check failed: required derived values are missing." >&2
    return 1
  fi

  echo "Apple rename check passed."
  return 0
}

run_create_flutter_app() {
  local flutter_platforms="${target_platforms// /,}"

  echo "create_flutter_app"
  echo "Running: cd \"$temp_directory\" && fvm flutter create --project-name \"$flutter_project_name\" --org it.alessandrorondolini --platforms=\"$flutter_platforms\" ."
  pushd "$temp_directory" >/dev/null
  if ! fvm flutter create --project-name "$flutter_project_name" --org it.alessandrorondolini --platforms="$flutter_platforms" .; then
    popd >/dev/null
    echo "Flutter app creation failed inside the temporary workspace." >&2
    return 1
  fi
  popd >/dev/null

  echo "Flutter app scaffold created in the temporary workspace."
  return 0
}

run_copy_into_repo() {
  if [[ -z "${repo_root:-}" ]]; then
    echo "Copy step failed: repository root is not available." >&2
    return 1
  fi

  echo "copy_into_repo"
  echo "Running: cp -R \"$temp_directory\"/. \"$repo_root\"/"
  if ! cp -R "$temp_directory"/. "$repo_root"/; then
    echo "Copy step failed while moving the generated scaffold into the repository root." >&2
    return 1
  fi

  echo "Generated scaffold copied into the repository root."
  return 0
}

run_add_dependencies() {
  if [[ -z "${repo_root:-}" ]]; then
    echo "Dependency step failed: repository root is not available." >&2
    return 1
  fi

  if [[ ! -f "$repo_root/pubspec.yaml" ]]; then
    echo "Dependency step failed: pubspec.yaml was not found in the repository root." >&2
    return 1
  fi

  echo "dependencies"
  if ! pushd "$repo_root" >/dev/null; then
    echo "Dependency step failed: unable to enter the repository root." >&2
    return 1
  fi

  echo "Running: fvm flutter pub add dio shared_preferences get go_router intl flutter_displaymode stack_trace skeletonizer url_launcher device_info_plus package_info_plus"
  if ! fvm flutter pub add dio shared_preferences get go_router intl flutter_displaymode stack_trace skeletonizer url_launcher device_info_plus package_info_plus; then
    popd >/dev/null
    echo "Dependency step failed while adding runtime dependencies." >&2
    return 1
  fi

  echo "Running: fvm flutter pub add --dev flutter_native_splash flutter_launcher_icons flutter_lints"
  if ! fvm flutter pub add --dev flutter_native_splash flutter_launcher_icons flutter_lints; then
    popd >/dev/null
    echo "Dependency step failed while adding dev dependencies." >&2
    return 1
  fi

  popd >/dev/null
  echo "Runtime and dev dependencies added."
  return 0
}

run_analysis_options() {
  if [[ -z "${repo_root:-}" ]]; then
    echo "Analysis options step failed: repository root is not available." >&2
    return 1
  fi

  if [[ ! -f "$repo_root/pubspec.yaml" ]]; then
    echo "Analysis options step failed: pubspec.yaml was not found in the repository root." >&2
    return 1
  fi

  local analysis_options_path="$repo_root/analysis_options.yaml"

  echo "analysis_options"
  echo "Writing: $analysis_options_path"
  if ! printf '%s\n' \
    'include: package:flutter_lints/flutter.yaml' \
    '' \
    'linter:' \
    '  rules:' \
    '    avoid_print: false' \
    '    prefer_single_quotes: false' \
    '    always_declare_return_types: true' \
    >"$analysis_options_path"; then
    echo "Analysis options step failed while writing analysis_options.yaml." >&2
    return 1
  fi

  echo "analysis_options.yaml baseline created."
  return 0
}

run_architecture_scaffold() {
  if [[ -z "${repo_root:-}" ]]; then
    echo "Architecture scaffold step failed: repository root is not available." >&2
    return 1
  fi

  if [[ ! -f "$repo_root/pubspec.yaml" ]]; then
    echo "Architecture scaffold step failed: pubspec.yaml was not found in the repository root." >&2
    return 1
  fi

  local app_class_name
  app_class_name="$(pascal_case "$flutter_project_name")App"

  echo "architecture_scaffold"
  echo "Creating canonical lib/, feature, routing, entrypoint, and localization files."

  if ! grep -qE '^[[:space:]]*flutter_localizations:[[:space:]]*$' "$repo_root/pubspec.yaml"; then
    local pubspec_tmp
    pubspec_tmp="$(mktemp)"
    awk '
      { print }
      /^[[:space:]]*dependencies:[[:space:]]*$/ && ! inserted {
        print "  flutter_localizations:"
        print "    sdk: flutter"
        inserted = 1
      }
    ' "$repo_root/pubspec.yaml" >"$pubspec_tmp"
    mv "$pubspec_tmp" "$repo_root/pubspec.yaml"
  fi

  if ! awk '
    /^flutter:[[:space:]]*$/ { in_flutter = 1; next }
    /^[^[:space:]]/ { in_flutter = 0 }
    in_flutter && /^[[:space:]]+generate:[[:space:]]*true[[:space:]]*$/ { found = 1 }
    END { exit found ? 0 : 1 }
  ' "$repo_root/pubspec.yaml"; then
    local pubspec_tmp
    pubspec_tmp="$(mktemp)"
    awk '
      { print }
      /^flutter:[[:space:]]*$/ && ! inserted {
        print "  generate: true"
        inserted = 1
      }
    ' "$repo_root/pubspec.yaml" >"$pubspec_tmp"
    mv "$pubspec_tmp" "$repo_root/pubspec.yaml"
  fi

	  mkdir -p \
	    "$repo_root/lib/core/bindings" \
	    "$repo_root/lib/core/config" \
	    "$repo_root/lib/core/network" \
	    "$repo_root/lib/core/routing" \
    "$repo_root/lib/core/shared_preferences/data/repo_impl" \
    "$repo_root/lib/core/shared_preferences/domain/repositories" \
    "$repo_root/lib/core/styles" \
    "$repo_root/lib/core/utils" \
    "$repo_root/lib/core/view/controllers" \
    "$repo_root/lib/core/view/data/repo_impl" \
    "$repo_root/lib/core/view/domain/repositories" \
    "$repo_root/lib/core/view/domain/use_cases" \
    "$repo_root/lib/core/view/widgets" \
    "$repo_root/lib/features/onboarding/view/bindings" \
    "$repo_root/lib/features/onboarding/view/controllers" \
    "$repo_root/lib/features/onboarding/view/pages" \
    "$repo_root/lib/features/onboarding/view/widgets" \
    "$repo_root/lib/features/onboarding/data/models" \
    "$repo_root/lib/features/onboarding/data/repo_impl" \
    "$repo_root/lib/features/onboarding/domain/entities" \
    "$repo_root/lib/features/onboarding/domain/repositories" \
    "$repo_root/lib/features/onboarding/domain/use_cases" \
    "$repo_root/lib/features/home/view/bindings" \
    "$repo_root/lib/features/home/view/controllers" \
    "$repo_root/lib/features/home/view/pages" \
    "$repo_root/lib/features/home/view/widgets" \
    "$repo_root/lib/features/home/data/models" \
    "$repo_root/lib/features/home/data/repo_impl" \
    "$repo_root/lib/features/home/domain/entities" \
    "$repo_root/lib/features/home/domain/repositories" \
    "$repo_root/lib/features/home/domain/use_cases" \
    "$repo_root/lib/features/profile/view/bindings" \
    "$repo_root/lib/features/profile/view/controllers" \
    "$repo_root/lib/features/profile/view/pages" \
    "$repo_root/lib/features/profile/view/widgets" \
    "$repo_root/lib/features/profile/data/models" \
    "$repo_root/lib/features/profile/data/repo_impl" \
    "$repo_root/lib/features/profile/domain/entities" \
    "$repo_root/lib/features/profile/domain/repositories" \
	    "$repo_root/lib/features/profile/domain/use_cases" \
	    "$repo_root/lib/l10n"

  if [[ -f "$repo_root/lib/main.dart" ]]; then
    echo "Removing generated Flutter template entrypoint: $repo_root/lib/main.dart"
    rm "$repo_root/lib/main.dart"
  fi

  if [[ -f "$repo_root/test/widget_test.dart" ]]; then
    echo "Removing generated Flutter template widget test: $repo_root/test/widget_test.dart"
    rm "$repo_root/test/widget_test.dart"
  fi

  if [[ -d "$repo_root/test" ]] && ! find "$repo_root/test" -mindepth 1 -print -quit | grep -q .; then
    rmdir "$repo_root/test"
  fi

  cat >"$repo_root/lib/core/config/app_config.dart" <<DART
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
DART

  cat >"$repo_root/lib/core/network/dio.dart" <<DART
import 'package:dio/dio.dart';
import 'package:$flutter_project_name/core/config/app_config.dart';

Dio provideDio({
  AppConfig? appConfig,
  List<Interceptor>? interceptors,
}) {
  final baseUrl = appConfig?.baseUrl ?? '';
  final options = BaseOptions(
    baseUrl: baseUrl.isEmpty ? '/api' : '\$baseUrl/api',
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
DART

  cat >"$repo_root/lib/core/bindings/core_bindings.dart" <<DART
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:$flutter_project_name/core/config/app_config.dart';
import 'package:$flutter_project_name/core/routing/routes.dart' as root_routes;
import 'package:$flutter_project_name/core/routing/shell_routes.dart' as shell_routes;
import 'package:$flutter_project_name/core/view/controllers/theme_controller.dart';
import 'package:$flutter_project_name/core/view/data/repo_impl/theme_repository_shared_prefs_impl.dart';
import 'package:$flutter_project_name/core/view/domain/repositories/theme_repository.dart';
import 'package:$flutter_project_name/core/view/domain/use_cases/get_theme_mode.dart';
import 'package:$flutter_project_name/core/view/domain/use_cases/set_theme_mode.dart';
import 'package:$flutter_project_name/core/network/dio.dart';

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
DART

  cat >"$repo_root/lib/app.dart" <<DART
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:$flutter_project_name/core/bindings/core_bindings.dart';
import 'package:$flutter_project_name/core/config/app_config.dart';
import 'package:$flutter_project_name/core/styles/app_base_theme.dart';
import 'package:$flutter_project_name/core/view/controllers/theme_controller.dart';
import 'package:$flutter_project_name/l10n/app_localizations.dart';

Future<void> bootstrapApp({required AppConfig config}) async {
  final preferences = await SharedPreferences.getInstance();
  CoreBindings(config: config, preferences: preferences).dependencies();

  runApp(const $app_class_name());
}

class $app_class_name extends StatelessWidget {
  const $app_class_name({super.key});

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
DART

  cat >"$repo_root/lib/core/routing/app_route.dart" <<'DART'
enum AppRoute {
  onboarding('/onboarding'),
  home('/home'),
  profile('/profile');

  final String path;

  const AppRoute(this.path);
}
DART

  cat >"$repo_root/lib/core/routing/go_router_observer.dart" <<'DART'
import 'package:flutter/widgets.dart';

class GoRouterObserver extends NavigatorObserver {}
DART

  cat >"$repo_root/lib/core/routing/routes.dart" <<DART
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:$flutter_project_name/core/routing/app_route.dart';
import 'package:$flutter_project_name/core/routing/go_router_observer.dart';
import 'package:$flutter_project_name/features/home/view/bindings/home_bindings.dart';
import 'package:$flutter_project_name/features/home/view/pages/home_page.dart';
import 'package:$flutter_project_name/features/onboarding/view/bindings/onboarding_bindings.dart';
import 'package:$flutter_project_name/features/onboarding/view/pages/onboarding_page.dart';
import 'package:$flutter_project_name/features/profile/view/bindings/profile_bindings.dart';
import 'package:$flutter_project_name/features/profile/view/pages/profile_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRootRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoute.onboarding.path,
    observers: [GoRouterObserver()],
    routes: [
      GoRoute(
        path: AppRoute.onboarding.path,
        name: AppRoute.onboarding.name,
        pageBuilder: (context, state) {
          const OnboardingBindings().dependencies();
          return const MaterialPage(child: OnboardingPage());
        },
      ),
      GoRoute(
        path: AppRoute.home.path,
        name: AppRoute.home.name,
        pageBuilder: (context, state) {
          const HomeBindings().dependencies();
          return const MaterialPage(child: HomePage());
        },
      ),
      GoRoute(
        path: AppRoute.profile.path,
        name: AppRoute.profile.name,
        pageBuilder: (context, state) {
          const ProfileBindings().dependencies();
          return const MaterialPage(child: ProfilePage());
        },
      ),
    ],
  );
}
DART

  cat >"$repo_root/lib/core/routing/shell_routes.dart" <<DART
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:$flutter_project_name/core/routing/app_route.dart';
import 'package:$flutter_project_name/core/routing/go_router_observer.dart';
import 'package:$flutter_project_name/core/view/widgets/app_shell.dart';
import 'package:$flutter_project_name/features/home/view/bindings/home_bindings.dart';
import 'package:$flutter_project_name/features/home/view/pages/home_page.dart';
import 'package:$flutter_project_name/features/onboarding/view/bindings/onboarding_bindings.dart';
import 'package:$flutter_project_name/features/onboarding/view/pages/onboarding_page.dart';
import 'package:$flutter_project_name/features/profile/view/bindings/profile_bindings.dart';
import 'package:$flutter_project_name/features/profile/view/pages/profile_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildShellRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoute.onboarding.path,
    observers: [GoRouterObserver()],
    routes: [
      GoRoute(
        path: AppRoute.onboarding.path,
        name: AppRoute.onboarding.name,
        pageBuilder: (context, state) {
          const OnboardingBindings().dependencies();
          return const MaterialPage(child: OnboardingPage());
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.home.path,
                name: AppRoute.home.name,
                pageBuilder: (context, state) {
                  const HomeBindings().dependencies();
                  return const MaterialPage(child: HomePage());
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.profile.path,
                name: AppRoute.profile.name,
                pageBuilder: (context, state) {
                  const ProfileBindings().dependencies();
                  return const MaterialPage(child: ProfilePage());
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
DART

  cat >"$repo_root/lib/core/view/widgets/app_shell.dart" <<'DART'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
DART

  cat >"$repo_root/lib/core/styles/app_colors.dart" <<'DART'
import 'package:flutter/material.dart';

abstract final class AppColors {
  static const lightSeed = Color(0xFF286A62);
  static const darkSeed = Color(0xFF6EC8B8);
}
DART

  cat >"$repo_root/lib/core/styles/app_text_styles.dart" <<'DART'
import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  static const title = TextStyle(fontSize: 28, fontWeight: FontWeight.w700);
  static const body = TextStyle(fontSize: 16, fontWeight: FontWeight.w400);
}
DART

  cat >"$repo_root/lib/core/styles/app_base_theme.dart" <<DART
import 'package:flutter/material.dart';
import 'package:$flutter_project_name/core/styles/app_colors.dart';

abstract final class AppBaseTheme {
  static ThemeData get light {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.lightSeed),
      useMaterial3: true,
    );
  }

  static ThemeData get dark {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.darkSeed,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}
DART

  cat >"$repo_root/lib/core/styles/app_breakpoints.dart" <<'DART'
import 'package:flutter/widgets.dart';

enum ScreenSize { compact, medium, expanded }

abstract final class AppBreakpoints {
  static const compact = 600.0;
  static const medium = 840.0;

  static ScreenSize of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < compact) return ScreenSize.compact;
    if (width < medium) return ScreenSize.medium;
    return ScreenSize.expanded;
  }
}
DART

  cat >"$repo_root/lib/core/styles/app_paddings.dart" <<'DART'
abstract final class AppPaddings {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}
DART

  cat >"$repo_root/lib/core/utils/app_key_store.dart" <<'DART'
abstract final class AppKeyStore {
  static const themeMode = 'theme_mode';
}
DART

  cat >"$repo_root/lib/core/utils/extensions.dart" <<'DART'
import 'package:flutter/widgets.dart';

extension BuildContextScreenSize on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
}
DART

  cat >"$repo_root/lib/core/view/domain/repositories/theme_repository.dart" <<'DART'
import 'package:flutter/material.dart';

abstract interface class ThemeRepository {
  Future<ThemeMode> getThemeMode();
  Future<void> saveThemeMode(ThemeMode mode);
}
DART

  cat >"$repo_root/lib/core/view/domain/use_cases/get_theme_mode.dart" <<DART
import 'package:flutter/material.dart';
import 'package:$flutter_project_name/core/view/domain/repositories/theme_repository.dart';

class GetThemeModeUseCase {
  const GetThemeModeUseCase(this._repository);

  final ThemeRepository _repository;

  Future<ThemeMode> call() {
    return _repository.getThemeMode();
  }
}
DART

  cat >"$repo_root/lib/core/view/domain/use_cases/set_theme_mode.dart" <<DART
import 'package:flutter/material.dart';
import 'package:$flutter_project_name/core/view/domain/repositories/theme_repository.dart';

class SetThemeModeUseCase {
  const SetThemeModeUseCase(this._repository);

  final ThemeRepository _repository;

  Future<void> call(ThemeMode mode) {
    return _repository.saveThemeMode(mode);
  }
}
DART

  cat >"$repo_root/lib/core/view/data/repo_impl/theme_repository_shared_prefs_impl.dart" <<DART
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:$flutter_project_name/core/utils/app_key_store.dart';
import 'package:$flutter_project_name/core/view/domain/repositories/theme_repository.dart';

class ThemeRepositorySharedPrefsImpl implements ThemeRepository {
  const ThemeRepositorySharedPrefsImpl(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<ThemeMode> getThemeMode() async {
    return ThemeMode.values.byName(
      _preferences.getString(AppKeyStore.themeMode) ?? ThemeMode.system.name,
    );
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    await _preferences.setString(AppKeyStore.themeMode, mode.name);
  }
}
DART

  cat >"$repo_root/lib/core/view/controllers/theme_controller.dart" <<DART
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:$flutter_project_name/core/view/domain/use_cases/get_theme_mode.dart';
import 'package:$flutter_project_name/core/view/domain/use_cases/set_theme_mode.dart';

class ThemeController extends GetxController {
  ThemeController({
    required GetThemeModeUseCase getThemeMode,
    required SetThemeModeUseCase setThemeModeUseCase,
  })  : _getThemeMode = getThemeMode,
        _setThemeMode = setThemeModeUseCase;

  final GetThemeModeUseCase _getThemeMode;
  final SetThemeModeUseCase _setThemeMode;
  final themeMode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    themeMode.value = await _getThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await _setThemeMode(mode);
  }
}
DART

  cat >"$repo_root/lib/core/shared_preferences/domain/repositories/preferences_repository.dart" <<'DART'
abstract interface class PreferencesRepository {
  String? readString(String key);
  Future<void> writeString(String key, String value);
}
DART

  cat >"$repo_root/lib/core/shared_preferences/data/repo_impl/preferences_repository_impl.dart" <<DART
import 'package:shared_preferences/shared_preferences.dart';
import 'package:$flutter_project_name/core/shared_preferences/domain/repositories/preferences_repository.dart';

class PreferencesRepositoryImpl implements PreferencesRepository {
  const PreferencesRepositoryImpl(this._preferences);

  final SharedPreferences _preferences;

  @override
  String? readString(String key) => _preferences.getString(key);

  @override
  Future<void> writeString(String key, String value) async {
    await _preferences.setString(key, value);
  }
}
DART

  for feature in onboarding home profile; do
    local feature_class
    feature_class="$(pascal_case "$feature")"
    cat >"$repo_root/lib/features/$feature/view/controllers/${feature}_controller.dart" <<DART
import 'package:get/get.dart';

class ${feature_class}Controller extends GetxController {
  final title = '${feature_class}'.obs;
}
DART
    cat >"$repo_root/lib/features/$feature/view/bindings/${feature}_bindings.dart" <<DART
import 'package:get/get.dart';

import 'package:$flutter_project_name/features/$feature/view/controllers/${feature}_controller.dart';

class ${feature_class}Bindings implements Bindings {
  const ${feature_class}Bindings();

  @override
  void dependencies() {
    if (!Get.isRegistered<${feature_class}Controller>()) {
      Get.lazyPut<${feature_class}Controller>(() => ${feature_class}Controller());
    }
  }
}
DART
    cat >"$repo_root/lib/features/$feature/view/pages/${feature}_page.dart" <<DART
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:$flutter_project_name/features/$feature/view/controllers/${feature}_controller.dart';

class ${feature_class}Page extends StatelessWidget {
  const ${feature_class}Page({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<${feature_class}Controller>();

    return Scaffold(
      appBar: AppBar(title: Text(controller.title.value)),
      body: Center(
        child: Obx(() => Text(controller.title.value)),
      ),
    );
  }
}
DART
  done

  cat >"$repo_root/lib/l10n/app_en.arb" <<'ARB'
{
  "@@locale": "en",
  "appTitle": "App"
}
ARB

  cat >"$repo_root/lib/l10n/app_it.arb" <<'ARB'
{
  "@@locale": "it",
  "appTitle": "App"
}
ARB

  cat >"$repo_root/l10n.yaml" <<'YAML'
arb-dir: lib/l10n
template-arb-file: app_it.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
nullable-getter: false
YAML

  local environment
  for environment in $environment_names; do
    mkdir -p "$repo_root/lib/entrypoints/$environment"
    cat >"$repo_root/lib/entrypoints/$environment/main.dart" <<DART
import 'package:flutter/material.dart';
import 'package:$flutter_project_name/app.dart';
import 'package:$flutter_project_name/core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config = AppConfig(
    environment: '$environment',
    displayName: '$app_display_name',
    baseUrl: '',
    routerShape: '$router_shape',
  );
  await bootstrapApp(config: config);
}
DART
  done

  echo "Architecture scaffold created."
  return 0
}

run_ide_config() {
  if [[ -z "${repo_root:-}" ]]; then
    echo "IDE config step failed: repository root is not available." >&2
    return 1
  fi

  echo "ide_config"
  mkdir -p "$repo_root/.vscode"

  local launch_json_path="$repo_root/.vscode/launch.json"
  echo "Writing: $launch_json_path"
  {
    printf '%s\n' '{'
    printf '%s\n' '  "version": "0.2.0",'
    printf '%s\n' '  "configurations": ['

    local environment
    local index=0
    local total=0
    for environment in $environment_names; do
      total=$((total + 1))
    done

    for environment in $environment_names; do
      index=$((index + 1))
      printf '%s\n' '    {'
      printf '      "name": "Flutter %s",\n' "$environment"
      printf '%s\n' '      "request": "launch",'
      printf '%s\n' '      "type": "dart",'
      printf '      "program": "lib/entrypoints/%s/main.dart"\n' "$environment"
      if [[ "$index" -lt "$total" ]]; then
        printf '%s\n' '    },'
      else
        printf '%s\n' '    }'
      fi
    done

    printf '%s\n' '  ]'
    printf '%s\n' '}'
  } >"$launch_json_path" || {
    echo "IDE config step failed while writing .vscode/launch.json." >&2
    return 1
  }

  if [[ -d "$repo_root/.idea" ]]; then
    local run_config_dir="$repo_root/.idea/runConfigurations"
    mkdir -p "$run_config_dir"

    local config_name
    for environment in $environment_names; do
      config_name="$(sanitize_snake_case "flutter_$environment")"
      echo "Writing: $run_config_dir/$config_name.xml"
      cat >"$run_config_dir/$config_name.xml" <<XML
<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="Flutter $environment" type="FlutterRunConfigurationType" factoryName="Flutter">
    <option name="filePath" value="\$PROJECT_DIR\$/lib/entrypoints/$environment/main.dart" />
    <method v="2" />
  </configuration>
</component>
XML
    done
  else
    echo "JetBrains config skipped: .idea directory not present."
  fi

  echo "IDE run configurations created."
  return 0
}

run_validation() {
  if [[ -z "${repo_root:-}" ]]; then
    echo "Validation step failed: repository root is not available." >&2
    return 1
  fi

  if [[ ! -f "$repo_root/pubspec.yaml" ]]; then
    echo "Validation step failed: pubspec.yaml was not found in the repository root." >&2
    return 1
  fi

  echo "validation"
  if ! pushd "$repo_root" >/dev/null; then
    echo "Validation step failed: unable to enter the repository root." >&2
    return 1
  fi

  echo "Running: fvm flutter pub get"
  if ! fvm flutter pub get; then
    popd >/dev/null
    echo "Validation step failed while running fvm flutter pub get." >&2
    return 1
  fi

  echo "Running: fvm flutter analyze"
  if ! fvm flutter analyze; then
    popd >/dev/null
    echo "Validation step failed while running fvm flutter analyze." >&2
    return 1
  fi

  popd >/dev/null
  echo "Validation completed successfully."
  return 0
}

run_cleanup() {
  if [[ -z "${temp_directory:-}" ]]; then
    return 0
  fi

  if [[ ! -d "$temp_directory" ]]; then
    temp_directory=""
    return 0
  fi

  echo "cleanup"
  echo "Removing temporary workspace: $temp_directory"
  if ! rm -rf "$temp_directory"; then
    echo "Cleanup step failed while removing the temporary workspace." >&2
    return 1
  fi

  temp_directory=""
  echo "Temporary workspace removed."
  return 0
}

detect_flutter_project() {
  local root="$1"

  if [[ -f "$root/pubspec.yaml" ]] && grep -qE '^[[:space:]]*flutter:[[:space:]]*$' "$root/pubspec.yaml"; then
    return 0
  fi

  if [[ -f "$root/pubspec.yaml" ]]; then
    if [[ -d "$root/lib" || -d "$root/android" || -d "$root/ios" ]]; then
      return 0
    fi

    if [[ -e "$root/analysis_options.yaml" || -d "$root/test" || -d "$root/web" || -d "$root/windows" || -d "$root/macos" || -d "$root/linux" ]]; then
      return 0
    fi
  fi

  return 1
}

classify_placeholder_file() {
  local path="$1"
  local name
  name="$(basename "$path")"

  if [[ ! -e "$path" ]]; then
    printf 'missing'
    return 0
  fi

  if [[ ! -s "$path" ]]; then
    printf 'placeholder (empty)'
    return 0
  fi

  case "$name" in
    README.md)
      if grep -qiE 'A new Flutter project|Getting Started|Flutter' "$path"; then
        printf 'likely placeholder'
      else
        printf 'custom, preserve'
      fi
      ;;
    .gitignore)
      if grep -qiE '\.dart_tool/|build/|Generated file|Flutter' "$path"; then
        printf 'likely placeholder'
      else
        printf 'custom, preserve'
      fi
      ;;
    LICENSE)
      if grep -qiE 'copyright|bsd|mit|apache' "$path"; then
        printf 'license file or custom content'
      else
        printf 'custom, preserve'
      fi
      ;;
    *)
      printf 'unknown'
      ;;
  esac
}

run_preflight() {
  local input_root="${1:-$PWD}"
  local git_root=""
  local target_root=""
  local issue_count=0

  if [[ ! -d "$input_root" ]]; then
    echo "Preflight error: target path does not exist: $input_root" >&2
    return 1
  fi

  target_root="$(cd "$input_root" && pwd)"

  echo "Preflight"
  echo "Target root: $target_root"
  if git_root="$(git -C "$target_root" rev-parse --show-toplevel 2>/dev/null)"; then
    echo "Git repository detected: $git_root"
  else
    echo "Git repository: not detected"
  fi
  repo_root="$target_root"

  if detect_flutter_project "$target_root"; then
    echo "Issue: existing Flutter project detected. Bootstrap must stop."
    issue_count=$((issue_count + 1))
  else
    echo "Flutter project detection: no coherent Flutter scaffold found"
  fi

  local flutter_signals=0
  if [[ -d "$target_root/lib" ]] || [[ -d "$target_root/android" ]] || [[ -d "$target_root/ios" ]] || [[ -e "$target_root/analysis_options.yaml" ]] || [[ -d "$target_root/test" ]] || [[ -d "$target_root/web" ]] || [[ -d "$target_root/windows" ]] || [[ -d "$target_root/macos" ]] || [[ -d "$target_root/linux" ]]; then
    flutter_signals=1
  fi

  if [[ ! -f "$target_root/pubspec.yaml" && "$flutter_signals" -eq 1 ]]; then
    echo "Issue: isolated Flutter-related files detected; target directory requires manual review."
    issue_count=$((issue_count + 1))
  fi

  echo "Placeholder scan"
  echo "README.md: $(classify_placeholder_file "$target_root/README.md")"
  echo ".gitignore: $(classify_placeholder_file "$target_root/.gitignore")"
  echo "LICENSE: $(classify_placeholder_file "$target_root/LICENSE")"

  if [[ "$issue_count" -gt 0 ]]; then
    echo "Preflight failed. Fix the issues above before bootstrapping."
    return 1
  fi

  echo "Preflight OK"
  return 0
}

join_by_comma() {
  local sep=""
  local item
  for item in "$@"; do
    printf '%s%s' "$sep" "$item"
    sep=", "
  done
}

prompt_non_empty() {
  local label="$1"
  local value=""

  while true; do
    read -r -p "$label: " value || return 1
    value="$(trim "$value")"
    if [[ -n "$value" ]]; then
      printf '%s' "$value"
      return 0
    fi
    echo "Value cannot be empty. Please try again." >&2
  done
}

render_checkbox_prompt() {
  local title="$1"
  local cursor_index="$2"
  local minimum="$3"
  local maximum="$4"
  shift 4
  local -a options=("$@")
  local marker=""
  local pointer=""
  local index=0

  printf '%s\n' "$title"
  printf '%s\n' "Use Up/Down arrows to move, Space to toggle, Enter to confirm."
  if [[ "$maximum" -gt 0 ]]; then
    printf '%s\n' "Selections: minimum $minimum, maximum $maximum"
  else
    printf '%s\n' "Minimum selections: $minimum"
  fi

  for index in "${!options[@]}"; do
    pointer=" "
    marker="[ ]"
    if [[ "${checkbox_selected[$index]}" -eq 1 ]]; then
      marker="[x]"
    fi
    if [[ "$index" -eq "$cursor_index" ]]; then
      pointer=">"
    fi
    printf '%s %s %s\n' "$pointer" "$marker" "${options[$index]}"
  done
}

read_checkbox_key() {
  local tty_path="$1"
  local tty_fd="$2"
  local key=""
  local remainder=""
  local next_char=""

  IFS= read -rsn1 -u "$tty_fd" key || return 1

  if [[ "$key" == $'\x1b' ]]; then
    remainder=""
    stty -echo -icanon time 1 min 0 <"$tty_path"
    while IFS= read -rsn1 -u "$tty_fd" next_char; do
      [[ -z "$next_char" ]] && break
      remainder+="$next_char"
      case "$remainder" in
        "[A"|"[B"|"OA"|"OB")
          break
          ;;
      esac
    done
    stty -echo -icanon time 0 min 1 <"$tty_path"
    key+="$remainder"
  fi

  checkbox_key="$key"
}

prompt_checkbox_selection() {
  local title="$1"
  local minimum="$2"
  local maximum="$3"
  shift 3
  local -a options=("$@")
  local cursor_index=0
  local selected_count=0
  local key=""
  local index
  local result=()
  local warning=""
  local tty_path="/dev/tty"
  local stty_state=""
  local tty_fd=3
  local checkbox_key=""

  if [[ ! -r "$tty_path" || ! -w "$tty_path" ]]; then
    echo "Interactive checkbox prompt requires a TTY." >&2
    return 1
  fi

  exec 3<>"$tty_path" || {
    echo "Interactive checkbox prompt could not open the TTY." >&2
    return 1
  }

  stty_state="$(stty -g <"$tty_path")"
  stty -echo -icanon time 0 min 1 <"$tty_path"

  checkbox_selected=()
  for _ in "${options[@]}"; do
    checkbox_selected+=(0)
  done

  if command -v tput >/dev/null 2>&1; then
    tput clear >"$tty_path"
  fi
  render_checkbox_prompt "$title" "$cursor_index" "$minimum" "$maximum" "${options[@]}" >"$tty_path"

  while true; do
    if ! read_checkbox_key "$tty_path" "$tty_fd"; then
      stty "$stty_state" <"$tty_path"
      exec 3>&-
      exec 3<&-
      return 1
    fi
    key="$checkbox_key"

    if [[ "$key" == $'\x1b[A' || "$key" == $'\x1bOA' || "$key" == "k" || "$key" == "K" ]]; then
      cursor_index=$((cursor_index - 1))
      if [[ "$cursor_index" -lt 0 ]]; then
        cursor_index=$((${#options[@]} - 1))
      fi
    elif [[ "$key" == $'\x1b[B' || "$key" == $'\x1bOB' || "$key" == "j" || "$key" == "J" ]]; then
      cursor_index=$((cursor_index + 1))
      if [[ "$cursor_index" -ge "${#options[@]}" ]]; then
        cursor_index=0
      fi
    elif [[ "$key" == " " ]]; then
      if [[ "${checkbox_selected[$cursor_index]}" -eq 1 ]]; then
        checkbox_selected[$cursor_index]=0
      else
        if [[ "$maximum" -eq 1 ]]; then
          for index in "${!options[@]}"; do
            checkbox_selected[$index]=0
          done
        elif [[ "$maximum" -gt 0 ]]; then
          selected_count=0
          for index in "${!options[@]}"; do
            if [[ "${checkbox_selected[$index]}" -eq 1 ]]; then
              selected_count=$((selected_count + 1))
            fi
          done
          if [[ "$selected_count" -ge "$maximum" ]]; then
            warning="Select at most $maximum option(s)."
            if command -v tput >/dev/null 2>&1; then
              tput clear >"$tty_path"
            fi
            render_checkbox_prompt "$title" "$cursor_index" "$minimum" "$maximum" "${options[@]}" >"$tty_path"
            printf '%s\n' "$warning" >"$tty_path"
            warning=""
            continue
          fi
        fi
        checkbox_selected[$cursor_index]=1
      fi
    elif [[ "$key" == "" || "$key" == $'\n' || "$key" == $'\r' ]]; then
      selected_count=0
      for index in "${!options[@]}"; do
        if [[ "${checkbox_selected[$index]}" -eq 1 ]]; then
          selected_count=$((selected_count + 1))
        fi
      done
      if [[ "$selected_count" -ge "$minimum" ]]; then
        if [[ "$maximum" -eq 0 || "$selected_count" -le "$maximum" ]]; then
          break
        fi
      fi
      if [[ "$selected_count" -lt "$minimum" ]]; then
        warning="Select at least $minimum option(s) before confirming."
      else
        warning="Select at most $maximum option(s) before confirming."
      fi
    fi

    if command -v tput >/dev/null 2>&1; then
      tput clear >"$tty_path"
    fi
    render_checkbox_prompt "$title" "$cursor_index" "$minimum" "$maximum" "${options[@]}" >"$tty_path"
    if [[ -n "$warning" ]]; then
      printf '%s\n' "$warning" >"$tty_path"
      warning=""
    fi
  done

  if command -v tput >/dev/null 2>&1; then
    tput clear >"$tty_path"
  fi
  stty "$stty_state" <"$tty_path"
  exec 3>&-
  exec 3<&-
  for index in "${!options[@]}"; do
    if [[ "${checkbox_selected[$index]}" -eq 1 ]]; then
      result+=("${options[$index]}")
    fi
  done

  printf '%s' "${result[*]}"
}

prompt_platforms() {
  prompt_checkbox_selection "target_platforms" 1 0 android ios web macos windows linux
}

prompt_environment_names() {
  prompt_checkbox_selection "environment_names" 2 0 dev test prod
}

prompt_router_shape() {
  prompt_checkbox_selection "router_shape" 1 1 root shell
}

echo "Bootstrap input collector"
run_preflight "${1:-$PWD}"
echo

temp_directory="$(create_temp_workspace)"
echo "Temp workspace"
echo "Created temp directory: $temp_directory"
echo
trap 'run_cleanup' EXIT

run_fvm_setup
echo

required_inputs="$(join_by_comma "${required_input_names[@]}")"
echo "Required inputs: $required_inputs"
echo

project_name=""
app_display_name=""
target_platforms=""
environment_names=""
router_shape=""

for input_name in "${required_input_names[@]}"; do
  [[ -z "$input_name" ]] && continue

  case "$input_name" in
    project_name)
      project_name="$(prompt_non_empty "project_name")"
      ;;
    app_display_name)
      app_display_name="$(prompt_non_empty "app_display_name")"
      ;;
    target_platforms)
      target_platforms="$(prompt_platforms)"
      ;;
    environment_names)
      environment_names="$(prompt_environment_names)"
      ;;
    router_shape)
      router_shape="$(prompt_router_shape)"
      ;;
    *)
      prompt_non_empty "$input_name" >/dev/null
      ;;
  esac

  echo
done

echo "Collected values"
echo "project_name: $project_name"
echo "app_display_name: $app_display_name"
echo "target_platforms: [$target_platforms]"
echo "environment_names: [$environment_names]"
echo "router_shape: $router_shape"

flutter_project_name="$(sanitize_snake_case "$project_name")"
platform_name="$(sanitize_platform_name "$project_name")"
platform_identifier_base="it.alessandrorondolini.$platform_name"

echo
echo "derived_values"
echo "organization_id: it.alessandrorondolini"
echo "flutter_project_name: $flutter_project_name"
echo "platform_identifier_base: $platform_identifier_base"
echo "android_namespace: $platform_identifier_base"
echo "android_application_id: $platform_identifier_base"
echo "ios_bundle_identifier: $platform_identifier_base"
echo "temp_directory: $temp_directory"
echo

confirm_apple_rename_readiness
run_create_flutter_app
run_copy_into_repo
run_add_dependencies
run_analysis_options
run_architecture_scaffold
run_ide_config
run_validation
run_cleanup
trap - EXIT
