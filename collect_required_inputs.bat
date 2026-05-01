@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "script_dir=%~dp0"
set "target_root=%~1"
if not defined target_root set "target_root=%CD%"
set "required_inputs=project_name,app_display_name,target_platforms,environment_names,router_shape"

call :run_preflight "%target_root%"
if errorlevel 1 exit /b 1

call :create_temp_workspace
if errorlevel 1 exit /b 1
echo Temp workspace
echo Created temp directory: !temp_directory!
echo.

call :run_fvm_setup
if errorlevel 1 (
  call :run_cleanup
  exit /b 1
)
echo.

echo Bootstrap input collector
echo Required inputs: %required_inputs%
echo.

for %%I in (%required_inputs:,= %) do (
  call :prompt_input %%I
  echo.
)

call :derive_values

echo Collected values
echo project_name: !project_name!
echo app_display_name: !app_display_name!
echo target_platforms: [!target_platforms!]
echo environment_names: [!environment_names!]
echo router_shape: !router_shape!
echo.
echo derived_values
echo organization_id: it.alessandrorondolini
echo flutter_project_name: !flutter_project_name!
echo platform_identifier_base: !platform_identifier_base!
echo android_namespace: !platform_identifier_base!
echo android_application_id: !platform_identifier_base!
echo ios_bundle_identifier: !platform_identifier_base!
echo temp_directory: !temp_directory!
echo.

call :confirm_apple_rename_readiness
if errorlevel 1 (
  call :run_cleanup
  exit /b 1
)

call :run_create_flutter_app
if errorlevel 1 (
  call :run_cleanup
  exit /b 1
)

call :run_copy_into_repo
if errorlevel 1 (
  call :run_cleanup
  exit /b 1
)

call :run_add_dependencies
if errorlevel 1 (
  call :run_cleanup
  exit /b 1
)

call :run_analysis_options
if errorlevel 1 (
  call :run_cleanup
  exit /b 1
)

call :run_architecture_scaffold
if errorlevel 1 (
  call :run_cleanup
  exit /b 1
)

call :run_ide_config
if errorlevel 1 (
  call :run_cleanup
  exit /b 1
)

call :run_validation
if errorlevel 1 (
  call :run_cleanup
  exit /b 1
)

call :run_cleanup
if errorlevel 1 exit /b 1
exit /b 0

:run_preflight
set "input_root=%~1"
set "git_root="
set "target_root_abs="
set "issue_count=0"

if not exist "%input_root%" (
  echo Preflight error: target path does not exist: %input_root%
  exit /b 1
)

for %%R in ("%input_root%") do set "target_root_abs=%%~fR"

echo Preflight
echo Target root: %target_root_abs%
for /f "delims=" %%R in ('git -C "%target_root_abs%" rev-parse --show-toplevel 2^>nul') do set "git_root=%%R"
if defined git_root (
  echo Git repository detected: %git_root%
) else (
  echo Git repository: not detected
)
set "repo_root=%target_root_abs%"

call :detect_flutter_project "%target_root_abs%"
set "flutter_status=%errorlevel%"

if "%flutter_status%"=="1" (
  echo Issue: existing Flutter project detected. Bootstrap must stop.
  set /a issue_count+=1
) else if "%flutter_status%"=="2" (
  echo Issue: isolated Flutter-related files detected; target directory requires manual review.
  set /a issue_count+=1
) else (
  echo Flutter project detection: no coherent Flutter scaffold found
)

call :classify_placeholder_file "%target_root_abs%\README.md" readme_class
call :classify_placeholder_file "%target_root_abs%\.gitignore" gitignore_class
call :classify_placeholder_file "%target_root_abs%\LICENSE" license_class
echo Placeholder scan
echo README.md: !readme_class!
echo .gitignore: !gitignore_class!
echo LICENSE: !license_class!

if !issue_count! gtr 0 (
  echo Preflight failed. Fix the issues above before bootstrapping.
  exit /b 1
)

echo Preflight OK
exit /b 0

:run_fvm_setup
set "fvm_path="
for /f "delims=" %%F in ('where fvm 2^>nul') do (
  if not defined fvm_path set "fvm_path=%%F"
)

if not defined fvm_path (
  echo FVM check failed: fvm was not found in PATH.
  echo Install FVM first, then rerun this script.
  exit /b 1
)

echo FVM setup
echo fvm found at: !fvm_path!

echo Running: fvm install stable
call fvm install stable
if errorlevel 1 (
  echo FVM setup failed while installing the stable Flutter SDK.
  exit /b 1
)

echo Running: fvm use stable --force --skip-pub-get
call fvm use stable --force --skip-pub-get
if errorlevel 1 (
  echo FVM setup failed while selecting the stable Flutter SDK.
  exit /b 1
)

echo Running: fvm flutter --version
call fvm flutter --version
if errorlevel 1 (
  echo FVM setup failed while verifying the Flutter SDK version.
  exit /b 1
)

echo FVM stable channel is ready.
exit /b 0

:confirm_apple_rename_readiness
set "apple_needed=0"
if not "!target_platforms:ios=!"=="!target_platforms!" set "apple_needed=1"
if not "!target_platforms:macos=!"=="!target_platforms!" set "apple_needed=1"

if "!apple_needed!"=="1" (
  echo Apple rename check
  echo Selected platforms include iOS or macOS.
  echo Derived Apple identifiers can be computed deterministically from the requested project name.
  if not defined flutter_project_name (
    echo Apple rename check failed: required derived values are missing.
    exit /b 1
  )
  if not defined platform_identifier_base (
    echo Apple rename check failed: required derived values are missing.
    exit /b 1
  )
  if not defined app_display_name (
    echo Apple rename check failed: required derived values are missing.
    exit /b 1
  )
  echo Apple rename check passed.
)

exit /b 0

:run_create_flutter_app
set "flutter_platforms=%target_platforms: =,%"
echo create_flutter_app
echo Running: cd /d "!temp_directory!" ^&^& fvm flutter create --project-name "!flutter_project_name!" --org it.alessandrorondolini --platforms=!flutter_platforms! .

pushd "!temp_directory!" >nul
if errorlevel 1 (
  echo Flutter app creation failed: unable to enter the temporary workspace.
  exit /b 1
)

call fvm flutter create --project-name "!flutter_project_name!" --org it.alessandrorondolini --platforms=!flutter_platforms! .
if errorlevel 1 (
  popd >nul
  echo Flutter app creation failed inside the temporary workspace.
  exit /b 1
)

popd >nul
echo Flutter app scaffold created in the temporary workspace.
exit /b 0

:run_copy_into_repo
if not defined repo_root (
  echo Copy step failed: repository root is not available.
  exit /b 1
)

echo copy_into_repo
echo Running: robocopy "!temp_directory!" "!repo_root!" /E /NFL /NDL /NJH /NJS /NC /NS /NP
robocopy "!temp_directory!" "!repo_root!" /E /NFL /NDL /NJH /NJS /NC /NS /NP >nul
set "robocopy_status=%errorlevel%"
if %robocopy_status% GEQ 8 (
  echo Copy step failed while moving the generated scaffold into the repository root.
  exit /b 1
)

echo Generated scaffold copied into the repository root.
exit /b 0

:run_add_dependencies
if not defined repo_root (
  echo Dependency step failed: repository root is not available.
  exit /b 1
)

if not exist "!repo_root!\pubspec.yaml" (
  echo Dependency step failed: pubspec.yaml was not found in the repository root.
  exit /b 1
)

echo dependencies
echo Running: cd /d "!repo_root!" ^&^& fvm flutter pub add dio shared_preferences get go_router intl flutter_displaymode stack_trace skeletonizer url_launcher device_info_plus package_info_plus

pushd "!repo_root!" >nul
if errorlevel 1 (
  echo Dependency step failed: unable to enter the repository root.
  exit /b 1
)

call fvm flutter pub add dio shared_preferences get go_router intl flutter_displaymode stack_trace skeletonizer url_launcher device_info_plus package_info_plus
if errorlevel 1 (
  popd >nul
  echo Dependency step failed while adding runtime dependencies.
  exit /b 1
)

echo Running: fvm flutter pub add --dev flutter_native_splash flutter_launcher_icons flutter_lints
call fvm flutter pub add --dev flutter_native_splash flutter_launcher_icons flutter_lints
if errorlevel 1 (
  popd >nul
  echo Dependency step failed while adding dev dependencies.
  exit /b 1
)

popd >nul
echo Runtime and dev dependencies added.
exit /b 0

:run_analysis_options
if not defined repo_root (
  echo Analysis options step failed: repository root is not available.
  exit /b 1
)

if not exist "!repo_root!\pubspec.yaml" (
  echo Analysis options step failed: pubspec.yaml was not found in the repository root.
  exit /b 1
)

set "analysis_options_path=!repo_root!\analysis_options.yaml"
echo analysis_options
echo Writing: !analysis_options_path!

> "!analysis_options_path!" (
  echo include: package:flutter_lints/flutter.yaml
  echo(
  echo linter:
  echo   rules:
  echo     avoid_print: false
  echo     prefer_single_quotes: false
  echo     always_declare_return_types: true
)
if errorlevel 1 (
  echo Analysis options step failed while writing analysis_options.yaml.
  exit /b 1
)

echo analysis_options.yaml baseline created.
exit /b 0

:render_template_file
set "template_path=%~1"
set "output_path=%~2"

if not exist "!template_path!" (
  echo Template render failed: template was not found: !template_path!
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "$template = Get-Content -Raw -Path $env:TEMPLATE_PATH; $template = $template.Replace('__PROJECT_NAME__', $env:FLUTTER_PROJECT_NAME); $encoding = New-Object System.Text.UTF8Encoding($false); [System.IO.File]::WriteAllText($env:OUTPUT_PATH, $template, $encoding)"
if errorlevel 1 (
  echo Template render failed while writing: !output_path!
  exit /b 1
)

exit /b 0

:run_architecture_scaffold
if not defined repo_root (
  echo Architecture scaffold step failed: repository root is not available.
  exit /b 1
)

if not exist "!repo_root!\pubspec.yaml" (
  echo Architecture scaffold step failed: pubspec.yaml was not found in the repository root.
  exit /b 1
)

call :pascal_case "!flutter_project_name!" app_class_base
set "app_class_name=!app_class_base!App"

echo architecture_scaffold
echo Creating canonical lib, feature, routing, entrypoint, and localization files.

set "PUBSPEC_PATH=!repo_root!\pubspec.yaml"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=$env:PUBSPEC_PATH; $lines=Get-Content -Path $p; if(-not ($lines -match '^\s*flutter_localizations:\s*$')) { $out=@(); foreach($line in $lines){ $out += $line; if($line -match '^\s*dependencies:\s*$'){ $out += '  flutter_localizations:'; $out += '    sdk: flutter' } }; Set-Content -Path $p -Value $out -Encoding utf8 }; $lines=Get-Content -Path $p; $inFlutter=$false; $hasGenerate=$false; foreach($line in $lines){ if($line -match '^flutter:\s*$'){ $inFlutter=$true; continue }; if($line -match '^\S'){ $inFlutter=$false }; if($inFlutter -and $line -match '^\s+generate:\s*true\s*$'){ $hasGenerate=$true } }; if(-not $hasGenerate) { $out=@(); foreach($line in $lines){ $out += $line; if($line -match '^flutter:\s*$'){ $out += '  generate: true' } }; Set-Content -Path $p -Value $out -Encoding utf8 }"
if errorlevel 1 (
  echo Architecture scaffold step failed while updating pubspec.yaml for localization generation.
  exit /b 1
)

mkdir "!repo_root!\lib\core\bindings" >nul 2>nul
mkdir "!repo_root!\lib\core\config" >nul 2>nul
mkdir "!repo_root!\lib\core\network" >nul 2>nul
mkdir "!repo_root!\lib\core\routing" >nul 2>nul
mkdir "!repo_root!\lib\core\routing\guards" >nul 2>nul
mkdir "!repo_root!\lib\core\styles" >nul 2>nul
mkdir "!repo_root!\lib\core\utils" >nul 2>nul
mkdir "!repo_root!\lib\core\view\controllers" >nul 2>nul
mkdir "!repo_root!\lib\core\view\data\repo_impl" >nul 2>nul
mkdir "!repo_root!\lib\core\view\domain\repositories" >nul 2>nul
mkdir "!repo_root!\lib\core\view\domain\use_cases" >nul 2>nul
mkdir "!repo_root!\lib\core\view\widgets" >nul 2>nul
mkdir "!repo_root!\lib\l10n" >nul 2>nul

mkdir "!repo_root!\lib\features\onboarding\data\models" >nul 2>nul
mkdir "!repo_root!\lib\features\onboarding\data\repo_impl" >nul 2>nul
mkdir "!repo_root!\lib\features\onboarding\domain\entities" >nul 2>nul
mkdir "!repo_root!\lib\features\onboarding\domain\repositories" >nul 2>nul
mkdir "!repo_root!\lib\features\onboarding\domain\use_cases" >nul 2>nul
mkdir "!repo_root!\lib\features\onboarding\view\bindings" >nul 2>nul
mkdir "!repo_root!\lib\features\onboarding\view\controllers" >nul 2>nul
mkdir "!repo_root!\lib\features\onboarding\view\pages" >nul 2>nul
mkdir "!repo_root!\lib\features\onboarding\view\widgets" >nul 2>nul

set "file=!repo_root!\lib\features\onboarding\domain\repositories\onboarding_repository.dart"
> "!file!" echo abstract interface class OnboardingRepository {
>> "!file!" echo   Future^<bool^> getOnboardingState();
>> "!file!" echo   Future^<void^> setOnboardingState(bool accepted);
>> "!file!" echo }

set "file=!repo_root!\lib\features\onboarding\domain\use_cases\get_onboarding_state.dart"
> "!file!" echo import 'package:!flutter_project_name!/features/onboarding/domain/repositories/onboarding_repository.dart';
>> "!file!" echo class GetOnboardingStateUseCase {
>> "!file!" echo   const GetOnboardingStateUseCase(this._repository);
>> "!file!" echo   final OnboardingRepository _repository;
>> "!file!" echo   Future^<bool^> call() =^> _repository.getOnboardingState();
>> "!file!" echo }

set "file=!repo_root!\lib\features\onboarding\domain\use_cases\set_onboarding_state.dart"
> "!file!" echo import 'package:!flutter_project_name!/features/onboarding/domain/repositories/onboarding_repository.dart';
>> "!file!" echo class SetOnboardingStateUseCase {
>> "!file!" echo   const SetOnboardingStateUseCase(this._repository);
>> "!file!" echo   final OnboardingRepository _repository;
>> "!file!" echo   Future^<void^> call(bool accepted) =^> _repository.setOnboardingState(accepted);
>> "!file!" echo }

set "file=!repo_root!\lib\features\onboarding\data\repo_impl\onboarding_repository_shared_prefs_impl.dart"
> "!file!" echo import 'package:shared_preferences/shared_preferences.dart';
>> "!file!" echo import 'package:!flutter_project_name!/core/utils/app_key_store.dart';
>> "!file!" echo import 'package:!flutter_project_name!/features/onboarding/domain/repositories/onboarding_repository.dart';
>> "!file!" echo class OnboardingRepositorySharedPrefsImpl implements OnboardingRepository {
>> "!file!" echo   const OnboardingRepositorySharedPrefsImpl(this._preferences);
>> "!file!" echo   final SharedPreferences _preferences;
>> "!file!" echo   @override
>> "!file!" echo   Future^<bool^> getOnboardingState() async =^> _preferences.getBool(AppKeyStore.onboardingAccepted) ?? false;
>> "!file!" echo   @override
>> "!file!" echo   Future^<void^> setOnboardingState(bool accepted) async { await _preferences.setBool(AppKeyStore.onboardingAccepted, accepted); }
>> "!file!" echo }

set "file=!repo_root!\lib\features\onboarding\view\controllers\onboarding_controller.dart"
> "!file!" echo import 'package:get/get.dart';
>> "!file!" echo import 'package:!flutter_project_name!/features/onboarding/domain/use_cases/get_onboarding_state.dart';
>> "!file!" echo import 'package:!flutter_project_name!/features/onboarding/domain/use_cases/set_onboarding_state.dart';
>> "!file!" echo class OnboardingController extends GetxController {
>> "!file!" echo   OnboardingController({required GetOnboardingStateUseCase getOnboardingState, required SetOnboardingStateUseCase setOnboardingState}) : _getOnboardingState = getOnboardingState, _setOnboardingState = setOnboardingState;
>> "!file!" echo   final GetOnboardingStateUseCase _getOnboardingState;
>> "!file!" echo   final SetOnboardingStateUseCase _setOnboardingState;
>> "!file!" echo   final title = 'Onboarding'.obs;
>> "!file!" echo   final isAccepted = false.obs;
>> "!file!" echo   final isLoading = true.obs;
>> "!file!" echo   @override
>> "!file!" echo   void onInit() { super.onInit(); _loadOnboardingState(); }
>> "!file!" echo   Future^<void^> _loadOnboardingState() async { isAccepted.value = await _getOnboardingState(); isLoading.value = false; }
>> "!file!" echo   Future^<void^> setAccepted(bool value) async { isAccepted.value = value; await _setOnboardingState(value); }
>> "!file!" echo }

set "file=!repo_root!\lib\features\onboarding\view\bindings\onboarding_bindings.dart"
> "!file!" echo import 'package:get/get.dart';
>> "!file!" echo import 'package:!flutter_project_name!/features/onboarding/domain/use_cases/get_onboarding_state.dart';
>> "!file!" echo import 'package:!flutter_project_name!/features/onboarding/domain/use_cases/set_onboarding_state.dart';
>> "!file!" echo import 'package:!flutter_project_name!/features/onboarding/view/controllers/onboarding_controller.dart';
>> "!file!" echo class OnboardingBindings implements Bindings {
>> "!file!" echo   const OnboardingBindings();
>> "!file!" echo   @override
>> "!file!" echo   void dependencies() {
>> "!file!" echo     if (Get.isRegistered^<OnboardingController^>() == false) Get.lazyPut^<OnboardingController^>(() =^> OnboardingController(getOnboardingState: Get.find^<GetOnboardingStateUseCase^>(), setOnboardingState: Get.find^<SetOnboardingStateUseCase^>()));
>> "!file!" echo   }
>> "!file!" echo }

set "file=!repo_root!\lib\features\onboarding\view\pages\onboarding_page.dart"
> "!file!" echo import 'package:flutter/material.dart';
>> "!file!" echo import 'package:get/get.dart';
>> "!file!" echo import 'package:go_router/go_router.dart';
>> "!file!" echo import 'package:!flutter_project_name!/core/routing/app_route.dart';
>> "!file!" echo import 'package:!flutter_project_name!/features/onboarding/view/controllers/onboarding_controller.dart';
>> "!file!" echo class OnboardingPage extends StatelessWidget {
>> "!file!" echo   const OnboardingPage({super.key});
>> "!file!" echo   @override
>> "!file!" echo   Widget build(BuildContext context) {
>> "!file!" echo     final controller = Get.find^<OnboardingController^>();
>> "!file!" echo     return Scaffold(
>> "!file!" echo       appBar: AppBar(title: Text(controller.title.value)),
>> "!file!" echo       body: SafeArea(
>> "!file!" echo         child: Padding(
>> "!file!" echo           padding: const EdgeInsets.all(24),
>> "!file!" echo           child: Obx(() {
>> "!file!" echo             if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
>> "!file!" echo             return Column(
>> "!file!" echo               crossAxisAlignment: CrossAxisAlignment.start,
>> "!file!" echo               children: [
>> "!file!" echo                 Text('Prima di continuare devi accettare l\'onboarding.', style: Theme.of(context).textTheme.headlineSmall),
>> "!file!" echo                 const SizedBox(height: 12),
>> "!file!" echo                 Text('Conferma di aver letto e accettato per sbloccare il pulsante di accesso alla home.', style: Theme.of(context).textTheme.bodyLarge),
>> "!file!" echo                 const Spacer(),
>> "!file!" echo                 CheckboxListTile(contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, title: const Text('Accetto e voglio proseguire'), value: controller.isAccepted.value, onChanged: (value) =^> controller.setAccepted(value ?? false)),
>> "!file!" echo                 const SizedBox(height: 16),
>> "!file!" echo                 SizedBox(width: double.infinity, child: ElevatedButton(onPressed: controller.isAccepted.value ? () =^> context.go(AppRoute.home.path) : null, child: const Text('Continua'))),
>> "!file!" echo               ],
>> "!file!" echo             );
>> "!file!" echo           }),
>> "!file!" echo         ),
>> "!file!" echo       ),
>> "!file!" echo     );
>> "!file!" echo   }
>> "!file!" echo }

for %%F in (home profile) do (
  mkdir "!repo_root!\lib\features\%%F\data\models" >nul 2>nul
  mkdir "!repo_root!\lib\features\%%F\data\repo_impl" >nul 2>nul
  mkdir "!repo_root!\lib\features\%%F\domain\entities" >nul 2>nul
  mkdir "!repo_root!\lib\features\%%F\domain\repositories" >nul 2>nul
  mkdir "!repo_root!\lib\features\%%F\domain\use_cases" >nul 2>nul
  mkdir "!repo_root!\lib\features\%%F\view\bindings" >nul 2>nul
  mkdir "!repo_root!\lib\features\%%F\view\controllers" >nul 2>nul
  mkdir "!repo_root!\lib\features\%%F\view\pages" >nul 2>nul
  mkdir "!repo_root!\lib\features\%%F\view\widgets" >nul 2>nul
)

if exist "!repo_root!\lib\main.dart" (
  echo Removing generated Flutter template entrypoint: !repo_root!\lib\main.dart
  del /Q "!repo_root!\lib\main.dart"
  if errorlevel 1 (
    echo Architecture scaffold step failed while removing lib\main.dart.
    exit /b 1
  )
)

if exist "!repo_root!\test\widget_test.dart" (
  echo Removing generated Flutter template widget test: !repo_root!\test\widget_test.dart
  del /Q "!repo_root!\test\widget_test.dart"
  if errorlevel 1 (
    echo Architecture scaffold step failed while removing test\widget_test.dart.
    exit /b 1
  )
)

if exist "!repo_root!\test" (
  dir /A /B "!repo_root!\test" 2>nul | findstr . >nul
  if errorlevel 1 rmdir "!repo_root!\test"
)

set "file=!repo_root!\lib\core\config\app_config.dart"
> "!file!" echo import 'package:flutter/foundation.dart';
>> "!file!" echo.
>> "!file!" echo @immutable
>> "!file!" echo class AppConfig {
>> "!file!" echo   const AppConfig({required this.environment, required this.displayName, required this.baseUrl, required this.routerShape});
>> "!file!" echo   final String environment;
>> "!file!" echo   final String displayName;
>> "!file!" echo   final String baseUrl;
>> "!file!" echo   final String routerShape;
>> "!file!" echo }

set "file=!repo_root!\lib\core\network\dio.dart"
> "!file!" echo import 'package:dio/dio.dart';
>> "!file!" echo.
>> "!file!" echo import 'package:!flutter_project_name!/core/config/app_config.dart';
>> "!file!" echo.
>> "!file!" echo Dio provideDio({
>> "!file!" echo   AppConfig? appConfig,
>> "!file!" echo   List^<Interceptor^>? interceptors,
>> "!file!" echo }) {
>> "!file!" echo   final baseUrl = appConfig?.baseUrl ?? '';
>> "!file!" echo   final options = BaseOptions(
>> "!file!" echo     baseUrl: baseUrl.isEmpty ? 'http://localhost:8080/api' : '$baseUrl/api',
>> "!file!" echo     headers: {'Accept': 'application/json'},
>> "!file!" echo     contentType: Headers.jsonContentType,
>> "!file!" echo     connectTimeout: const Duration(milliseconds: 130000),
>> "!file!" echo     receiveTimeout: const Duration(milliseconds: 130000),
>> "!file!" echo   );
>> "!file!" echo   final dio = Dio(options);
>> "!file!" echo.
>> "!file!" echo   if (interceptors != null) {
>> "!file!" echo     for (final interceptor in interceptors) {
>> "!file!" echo       dio.interceptors.add(interceptor);
>> "!file!" echo     }
>> "!file!" echo   }
>> "!file!" echo   return dio;
>> "!file!" echo }

set "file=!repo_root!\lib\core\bindings\core_bindings.dart"
> "!file!" echo import 'package:dio/dio.dart';
>> "!file!" echo import 'package:get/get.dart';
>> "!file!" echo import 'package:go_router/go_router.dart';
>> "!file!" echo import 'package:shared_preferences/shared_preferences.dart';
>> "!file!" echo.
>> "!file!" echo import 'package:!flutter_project_name!/core/config/app_config.dart';
>> "!file!" echo import 'package:!flutter_project_name!/core/routing/routes.dart' as root_routes;
>> "!file!" echo import 'package:!flutter_project_name!/core/routing/shell_routes.dart' as shell_routes;
>> "!file!" echo import 'package:!flutter_project_name!/core/view/controllers/theme_controller.dart';
>> "!file!" echo import 'package:!flutter_project_name!/core/view/data/repo_impl/theme_repository_shared_prefs_impl.dart';
>> "!file!" echo import 'package:!flutter_project_name!/core/view/domain/repositories/theme_repository.dart';
>> "!file!" echo import 'package:!flutter_project_name!/core/view/domain/use_cases/get_theme_mode.dart';
>> "!file!" echo import 'package:!flutter_project_name!/core/view/domain/use_cases/set_theme_mode.dart';
>> "!file!" echo import 'package:!flutter_project_name!/features/onboarding/data/repo_impl/onboarding_repository_shared_prefs_impl.dart';
>> "!file!" echo import 'package:!flutter_project_name!/features/onboarding/domain/repositories/onboarding_repository.dart';
>> "!file!" echo import 'package:!flutter_project_name!/features/onboarding/domain/use_cases/get_onboarding_state.dart';
>> "!file!" echo import 'package:!flutter_project_name!/features/onboarding/domain/use_cases/set_onboarding_state.dart';
>> "!file!" echo import 'package:!flutter_project_name!/core/network/dio.dart';
>> "!file!" echo.
>> "!file!" echo class CoreBindings implements Bindings {
>> "!file!" echo   const CoreBindings({required this.config, required this.preferences});
>> "!file!" echo   final AppConfig config;
>> "!file!" echo   final SharedPreferences preferences;
>> "!file!" echo   @override
>> "!file!" echo   void dependencies() {
>> "!file!" echo     Get.put^<AppConfig^>(config, permanent: true);
>> "!file!" echo     Get.put^<SharedPreferences^>(preferences, permanent: true);
>> "!file!" echo     Get.put^<Dio^>(provideDio(appConfig: config), permanent: true);
>> "!file!" echo     Get.put^<ThemeRepository^>(ThemeRepositorySharedPrefsImpl(preferences), permanent: true);
>> "!file!" echo     Get.put^<GetThemeModeUseCase^>(GetThemeModeUseCase(Get.find^<ThemeRepository^>()), permanent: true);
>> "!file!" echo     Get.put^<SetThemeModeUseCase^>(SetThemeModeUseCase(Get.find^<ThemeRepository^>()), permanent: true);
>> "!file!" echo     Get.put^<OnboardingRepository^>(OnboardingRepositorySharedPrefsImpl(preferences), permanent: true);
>> "!file!" echo     Get.put^<GetOnboardingStateUseCase^>(GetOnboardingStateUseCase(Get.find^<OnboardingRepository^>()), permanent: true);
>> "!file!" echo     Get.put^<SetOnboardingStateUseCase^>(SetOnboardingStateUseCase(Get.find^<OnboardingRepository^>()), permanent: true);
>> "!file!" echo     Get.put^<ThemeController^>(ThemeController(getThemeMode: Get.find^<GetThemeModeUseCase^>(), setThemeModeUseCase: Get.find^<SetThemeModeUseCase^>()), permanent: true);
>> "!file!" echo     final router = config.routerShape == 'shell' ? shell_routes.buildShellRouter() : root_routes.buildRootRouter();
>> "!file!" echo     Get.put^<GoRouter^>(router, permanent: true);
>> "!file!" echo   }
>> "!file!" echo }

set "file=!repo_root!\lib\app.dart"
> "!file!" echo import 'package:flutter/material.dart';
>> "!file!" echo import 'package:get/get.dart';
>> "!file!" echo import 'package:go_router/go_router.dart';
>> "!file!" echo import 'package:shared_preferences/shared_preferences.dart';
>> "!file!" echo.
>> "!file!" echo import 'package:!flutter_project_name!/core/bindings/core_bindings.dart';
>> "!file!" echo import 'package:!flutter_project_name!/core/config/app_config.dart';
>> "!file!" echo import 'package:!flutter_project_name!/l10n/app_localizations.dart';
>> "!file!" echo.
>> "!file!" echo Future^<void^> bootstrapApp({required AppConfig config}) async {
>> "!file!" echo   final preferences = await SharedPreferences.getInstance();
>> "!file!" echo   CoreBindings(config: config, preferences: preferences).dependencies();
>> "!file!" echo.
>> "!file!" echo   runApp(const !app_class_name!());
>> "!file!" echo }
>> "!file!" echo.
>> "!file!" echo class !app_class_name! extends StatelessWidget {
>> "!file!" echo   const !app_class_name!({super.key});
>> "!file!" echo   @override
>> "!file!" echo   Widget build(BuildContext context) {
>> "!file!" echo     final config = Get.find^<AppConfig^>();
>> "!file!" echo     final router = Get.find^<GoRouter^>();
>> "!file!" echo     return MaterialApp.router(
>> "!file!" echo       title: config.displayName,
>> "!file!" echo       routerConfig: router,
>> "!file!" echo       localizationsDelegates: AppLocalizations.localizationsDelegates,
>> "!file!" echo       supportedLocales: AppLocalizations.supportedLocales,
>> "!file!" echo     );
>> "!file!" echo   }
>> "!file!" echo }

set "file=!repo_root!\lib\core\routing\app_route.dart"
> "!file!" echo enum AppRoute {
>> "!file!" echo   onboarding('/onboarding'),
>> "!file!" echo   home('/home'),
>> "!file!" echo   profile('/profile');
>> "!file!" echo   final String path;
>> "!file!" echo   const AppRoute(this.path);
>> "!file!" echo }

set "file=!repo_root!\lib\core\routing\go_router_observer.dart"
> "!file!" echo import 'package:flutter/widgets.dart';
>> "!file!" echo class GoRouterObserver extends NavigatorObserver {}

set "file=!repo_root!\lib\core\routing\routes.dart"
> "!file!" echo import 'package:flutter/material.dart';
>> "!file!" echo import 'package:go_router/go_router.dart';
>> "!file!" echo import 'package:!flutter_project_name!/core/routing/app_route.dart';
>> "!file!" echo import 'package:!flutter_project_name!/core/routing/guards/onboarding_redirect.dart';
>> "!file!" echo import 'package:!flutter_project_name!/core/routing/go_router_observer.dart';
>> "!file!" echo import 'package:!flutter_project_name!/features/home/view/bindings/home_bindings.dart';
>> "!file!" echo import 'package:!flutter_project_name!/features/home/view/pages/home_page.dart';
>> "!file!" echo import 'package:!flutter_project_name!/features/onboarding/view/bindings/onboarding_bindings.dart';
>> "!file!" echo import 'package:!flutter_project_name!/features/onboarding/view/pages/onboarding_page.dart';
>> "!file!" echo import 'package:!flutter_project_name!/features/profile/view/bindings/profile_bindings.dart';
>> "!file!" echo import 'package:!flutter_project_name!/features/profile/view/pages/profile_page.dart';
>> "!file!" echo final rootNavigatorKey = GlobalKey^<NavigatorState^>();
>> "!file!" echo GoRouter buildRootRouter() {
>> "!file!" echo   return GoRouter(navigatorKey: rootNavigatorKey, initialLocation: AppRoute.onboarding.path, observers: [GoRouterObserver()], redirect: redirectOnboardingGuard, routes: [
>> "!file!" echo     GoRoute(path: AppRoute.onboarding.path, name: AppRoute.onboarding.name, pageBuilder: (context, state) {
>> "!file!" echo       const OnboardingBindings().dependencies();
>> "!file!" echo       return const MaterialPage(child: OnboardingPage());
>> "!file!" echo     }),
>> "!file!" echo     GoRoute(path: AppRoute.home.path, name: AppRoute.home.name, pageBuilder: (context, state) {
>> "!file!" echo       const HomeBindings().dependencies();
>> "!file!" echo       return const MaterialPage(child: HomePage());
>> "!file!" echo     }),
>> "!file!" echo     GoRoute(path: AppRoute.profile.path, name: AppRoute.profile.name, pageBuilder: (context, state) {
>> "!file!" echo       const ProfileBindings().dependencies();
>> "!file!" echo       return const MaterialPage(child: ProfilePage());
>> "!file!" echo     }),
>> "!file!" echo   ]);
>> "!file!" echo }

set "file=!repo_root!\lib\core\routing\shell_routes.dart"
> "!file!" echo import 'package:flutter/material.dart';
>> "!file!" echo import 'package:go_router/go_router.dart';
>> "!file!" echo import 'package:!flutter_project_name!/core/routing/app_route.dart';
>> "!file!" echo import 'package:!flutter_project_name!/core/routing/guards/onboarding_redirect.dart';
>> "!file!" echo import 'package:!flutter_project_name!/core/routing/go_router_observer.dart';
>> "!file!" echo import 'package:!flutter_project_name!/core/view/widgets/app_shell.dart';
>> "!file!" echo import 'package:!flutter_project_name!/features/home/view/bindings/home_bindings.dart';
>> "!file!" echo import 'package:!flutter_project_name!/features/home/view/pages/home_page.dart';
>> "!file!" echo import 'package:!flutter_project_name!/features/onboarding/view/bindings/onboarding_bindings.dart';
>> "!file!" echo import 'package:!flutter_project_name!/features/onboarding/view/pages/onboarding_page.dart';
>> "!file!" echo import 'package:!flutter_project_name!/features/profile/view/bindings/profile_bindings.dart';
>> "!file!" echo import 'package:!flutter_project_name!/features/profile/view/pages/profile_page.dart';
>> "!file!" echo final rootNavigatorKey = GlobalKey^<NavigatorState^>();
>> "!file!" echo GoRouter buildShellRouter() {
>> "!file!" echo   return GoRouter(navigatorKey: rootNavigatorKey, initialLocation: AppRoute.onboarding.path, observers: [GoRouterObserver()], redirect: redirectOnboardingGuard, routes: [
>> "!file!" echo     GoRoute(path: AppRoute.onboarding.path, name: AppRoute.onboarding.name, pageBuilder: (context, state) {
>> "!file!" echo       const OnboardingBindings().dependencies();
>> "!file!" echo       return const MaterialPage(child: OnboardingPage());
>> "!file!" echo     }),
>> "!file!" echo     StatefulShellRoute.indexedStack(builder: (context, state, navigationShell) =^> AppShell(navigationShell: navigationShell), branches: [
>> "!file!" echo       StatefulShellBranch(routes: [GoRoute(path: AppRoute.home.path, name: AppRoute.home.name, pageBuilder: (context, state) {
>> "!file!" echo         const HomeBindings().dependencies();
>> "!file!" echo         return const MaterialPage(child: HomePage());
>> "!file!" echo       })]),
>> "!file!" echo       StatefulShellBranch(routes: [GoRoute(path: AppRoute.profile.path, name: AppRoute.profile.name, pageBuilder: (context, state) {
>> "!file!" echo         const ProfileBindings().dependencies();
>> "!file!" echo         return const MaterialPage(child: ProfilePage());
>> "!file!" echo       })]),
>> "!file!" echo     ]),
>> "!file!" echo   ]);
>> "!file!" echo }

set "file=!repo_root!\lib\core\view\widgets\app_shell.dart"
> "!file!" echo import 'package:flutter/material.dart';
>> "!file!" echo import 'package:go_router/go_router.dart';
>> "!file!" echo class AppShell extends StatelessWidget {
>> "!file!" echo   const AppShell({required this.navigationShell, super.key});
>> "!file!" echo   final StatefulNavigationShell navigationShell;
>> "!file!" echo   @override
>> "!file!" echo   Widget build(BuildContext context) {
>> "!file!" echo     return Scaffold(body: navigationShell, bottomNavigationBar: NavigationBar(selectedIndex: navigationShell.currentIndex, onDestinationSelected: navigationShell.goBranch, destinations: const [
>> "!file!" echo       NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
>> "!file!" echo       NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
>> "!file!" echo     ]));
>> "!file!" echo   }
>> "!file!" echo }

for %%F in (home profile) do (
  call :pascal_case "%%F" feature_class
  set "file=!repo_root!\lib\features\%%F\view\controllers\%%F_controller.dart"
  > "!file!" echo import 'package:get/get.dart';
  >> "!file!" echo class !feature_class!Controller extends GetxController {
  >> "!file!" echo   final title = '!feature_class!'.obs;
  >> "!file!" echo }
  set "file=!repo_root!\lib\features\%%F\view\bindings\%%F_bindings.dart"
  > "!file!" echo import 'package:get/get.dart';
  >> "!file!" echo import 'package:!flutter_project_name!/features/%%F/view/controllers/%%F_controller.dart';
  >> "!file!" echo class !feature_class!Bindings implements Bindings {
  >> "!file!" echo   const !feature_class!Bindings();
  >> "!file!" echo   @override
  >> "!file!" echo   void dependencies() {
  >> "!file!" echo     if (Get.isRegistered^<!feature_class!Controller^>() == false) Get.lazyPut^<!feature_class!Controller^>(() =^> !feature_class!Controller());
  >> "!file!" echo   }
  >> "!file!" echo }
  set "file=!repo_root!\lib\features\%%F\view\pages\%%F_page.dart"
  > "!file!" echo import 'package:flutter/material.dart';
  >> "!file!" echo class !feature_class!Page extends StatelessWidget {
  >> "!file!" echo   const !feature_class!Page({super.key});
  >> "!file!" echo   @override
  >> "!file!" echo   Widget build(BuildContext context) =^> const Scaffold(body: Center(child: Text('!feature_class!')));
  >> "!file!" echo }
)

set "file=!repo_root!\lib\core\styles\app_colors.dart"
set "TEMPLATE_PATH=%script_dir%templates\lib\core\styles\app_colors.dart.tpl"
set "OUTPUT_PATH=!file!"
set "FLUTTER_PROJECT_NAME=!flutter_project_name!"
call :render_template_file "!TEMPLATE_PATH!" "!OUTPUT_PATH!"
if errorlevel 1 (
  echo Architecture scaffold step failed while rendering app_colors.dart.
  exit /b 1
)
set "file=!repo_root!\lib\core\styles\app_base_theme.dart"
set "TEMPLATE_PATH=%script_dir%templates\lib\core\styles\app_base_theme.dart.tpl"
set "OUTPUT_PATH=!file!"
set "FLUTTER_PROJECT_NAME=!flutter_project_name!"
call :render_template_file "!TEMPLATE_PATH!" "!OUTPUT_PATH!"
if errorlevel 1 (
  echo Architecture scaffold step failed while rendering app_base_theme.dart.
  exit /b 1
)
set "file=!repo_root!\lib\core\styles\app_breakpoints.dart"
> "!file!" echo enum ScreenSize { compact, medium, expanded }
set "file=!repo_root!\lib\core\styles\app_paddings.dart"
> "!file!" echo abstract class AppPaddings {
>> "!file!" echo   static const double xs = 4.0;
>> "!file!" echo   static const double s = 8.0;
>> "!file!" echo   static const double m = 12.0;
>> "!file!" echo   static const double l = 16.0;
>> "!file!" echo   static const double xl = 20.0;
>> "!file!" echo   static const double xxl = 24.0;
>> "!file!" echo   static const double xxxl = 36.0;
>> "!file!" echo   static const double venti = 72.0;
>> "!file!" echo   static const double giant = 144.0;
>> "!file!" echo }
set "file=!repo_root!\lib\core\styles\app_text_styles.dart"
> "!file!" echo import 'package:flutter/material.dart';
>> "!file!" echo.
>> "!file!" echo abstract class AppTextStyles {
>> "!file!" echo   // ───────────────────── Display ─────────────────────
>> "!file!" echo   static const TextStyle displayLarge = TextStyle(
>> "!file!" echo     fontSize: 57,
>> "!file!" echo     fontWeight: FontWeight.bold,
>> "!file!" echo     height: 64 / 57,
>> "!file!" echo     letterSpacing: -0.25,
>> "!file!" echo   ^);
>> "!file!" echo   static const TextStyle displayLargeItalic = TextStyle(
>> "!file!" echo     fontSize: 57,
>> "!file!" echo     fontWeight: FontWeight.bold,
>> "!file!" echo     height: 64 / 57,
>> "!file!" echo     letterSpacing: -0.25,
>> "!file!" echo     fontStyle: FontStyle.italic,
>> "!file!" echo   ^);
>> "!file!" echo.
>> "!file!" echo   static const TextStyle displayMedium = TextStyle(
>> "!file!" echo     fontSize: 45,
>> "!file!" echo     fontWeight: FontWeight.bold,
>> "!file!" echo     height: 52 / 45,
>> "!file!" echo   ^);
>> "!file!" echo   static const TextStyle displayMediumItalic = TextStyle(
>> "!file!" echo     fontSize: 45,
>> "!file!" echo     fontWeight: FontWeight.bold,
>> "!file!" echo     height: 52 / 45,
>> "!file!" echo     fontStyle: FontStyle.italic,
>> "!file!" echo   ^);
>> "!file!" echo.
>> "!file!" echo   static const TextStyle displaySmall = TextStyle(
>> "!file!" echo     fontSize: 36,
>> "!file!" echo     fontWeight: FontWeight.w700,
>> "!file!" echo     height: 44 / 36,
>> "!file!" echo   ^);
>> "!file!" echo   static const TextStyle displaySmallItalic = TextStyle(
>> "!file!" echo     fontSize: 36,
>> "!file!" echo     fontWeight: FontWeight.w700,
>> "!file!" echo     height: 44 / 36,
>> "!file!" echo     fontStyle: FontStyle.italic,
>> "!file!" echo   ^);
>> "!file!" echo.
>> "!file!" echo   // ───────────────────── Headlines ─────────────────────
>> "!file!" echo   static const TextStyle headlineLarge = TextStyle(
>> "!file!" echo     fontSize: 32,
>> "!file!" echo     fontWeight: FontWeight.w700,
>> "!file!" echo     height: 40 / 32,
>> "!file!" echo   ^);
>> "!file!" echo   static const TextStyle headlineLargeItalic = TextStyle(
>> "!file!" echo     fontSize: 32,
>> "!file!" echo     fontWeight: FontWeight.w700,
>> "!file!" echo     height: 40 / 32,
>> "!file!" echo     fontStyle: FontStyle.italic,
>> "!file!" echo   ^);
>> "!file!" echo.
>> "!file!" echo   static const TextStyle headlineMedium = TextStyle(
>> "!file!" echo     fontSize: 28,
>> "!file!" echo     fontWeight: FontWeight.w700,
>> "!file!" echo     height: 36 / 28,
>> "!file!" echo   ^);
>> "!file!" echo   static const TextStyle headlineMediumItalic = TextStyle(
>> "!file!" echo     fontSize: 28,
>> "!file!" echo     fontWeight: FontWeight.w700,
>> "!file!" echo     height: 36 / 28,
>> "!file!" echo     fontStyle: FontStyle.italic,
>> "!file!" echo   ^);
>> "!file!" echo.
>> "!file!" echo   static const TextStyle headlineSmall = TextStyle(
>> "!file!" echo     fontSize: 24,
>> "!file!" echo     fontWeight: FontWeight.w700,
>> "!file!" echo     height: 32 / 24,
>> "!file!" echo   ^);
>> "!file!" echo   static const TextStyle headlineSmallItalic = TextStyle(
>> "!file!" echo     fontSize: 24,
>> "!file!" echo     fontWeight: FontWeight.w700,
>> "!file!" echo     height: 32 / 24,
>> "!file!" echo     fontStyle: FontStyle.italic,
>> "!file!" echo   ^);
>> "!file!" echo.
>> "!file!" echo   // ───────────────────── Titles ─────────────────────
>> "!file!" echo   static const TextStyle titleLarge = TextStyle(
>> "!file!" echo     fontSize: 22,
>> "!file!" echo     fontWeight: FontWeight.w600,
>> "!file!" echo     height: 28 / 22,
>> "!file!" echo   ^);
>> "!file!" echo   static const TextStyle titleLargeItalic = TextStyle(
>> "!file!" echo     fontSize: 22,
>> "!file!" echo     fontWeight: FontWeight.w600,
>> "!file!" echo     height: 28 / 22,
>> "!file!" echo     fontStyle: FontStyle.italic,
>> "!file!" echo   ^);
>> "!file!" echo.
>> "!file!" echo   static const TextStyle titleMedium = TextStyle(
>> "!file!" echo     fontSize: 16,
>> "!file!" echo     fontWeight: FontWeight.w600,
>> "!file!" echo     height: 24 / 16,
>> "!file!" echo     letterSpacing: 0.15,
>> "!file!" echo   ^);
>> "!file!" echo   static const TextStyle titleMediumItalic = TextStyle(
>> "!file!" echo     fontSize: 16,
>> "!file!" echo     fontWeight: FontWeight.w600,
>> "!file!" echo     height: 24 / 16,
>> "!file!" echo     letterSpacing: 0.15,
>> "!file!" echo     fontStyle: FontStyle.italic,
>> "!file!" echo   ^);
>> "!file!" echo.
>> "!file!" echo   static const TextStyle titleSmall = TextStyle(
>> "!file!" echo     fontSize: 14,
>> "!file!" echo     fontWeight: FontWeight.w600,
>> "!file!" echo     height: 20 / 14,
>> "!file!" echo     letterSpacing: 0.1,
>> "!file!" echo   ^);
>> "!file!" echo   static const TextStyle titleSmallItalic = TextStyle(
>> "!file!" echo     fontSize: 14,
>> "!file!" echo     fontWeight: FontWeight.w600,
>> "!file!" echo     height: 20 / 14,
>> "!file!" echo     letterSpacing: 0.1,
>> "!file!" echo     fontStyle: FontStyle.italic,
>> "!file!" echo   ^);
>> "!file!" echo.
>> "!file!" echo   // ───────────────────── Body ─────────────────────
>> "!file!" echo   static const TextStyle bodyLarge = TextStyle(
>> "!file!" echo     fontSize: 16,
>> "!file!" echo     fontWeight: FontWeight.w400,
>> "!file!" echo     height: 24 / 16,
>> "!file!" echo     letterSpacing: 0.5,
>> "!file!" echo   ^);
>> "!file!" echo   static const TextStyle bodyLargeItalic = TextStyle(
>> "!file!" echo     fontSize: 16,
>> "!file!" echo     fontWeight: FontWeight.w400,
>> "!file!" echo     height: 24 / 16,
>> "!file!" echo     letterSpacing: 0.5,
>> "!file!" echo     fontStyle: FontStyle.italic,
>> "!file!" echo   ^);
>> "!file!" echo.
>> "!file!" echo   static const TextStyle bodyMedium = TextStyle(
>> "!file!" echo     fontSize: 14,
>> "!file!" echo     fontWeight: FontWeight.w400,
>> "!file!" echo     height: 20 / 14,
>> "!file!" echo     letterSpacing: 0.25,
>> "!file!" echo   ^);
>> "!file!" echo   static const TextStyle bodyMediumItalic = TextStyle(
>> "!file!" echo     fontSize: 14,
>> "!file!" echo     fontWeight: FontWeight.w400,
>> "!file!" echo     height: 20 / 14,
>> "!file!" echo     letterSpacing: 0.25,
>> "!file!" echo     fontStyle: FontStyle.italic,
>> "!file!" echo   ^);
>> "!file!" echo.
>> "!file!" echo   static const TextStyle bodySmall = TextStyle(
>> "!file!" echo     fontSize: 12,
>> "!file!" echo     fontWeight: FontWeight.w400,
>> "!file!" echo     height: 16 / 12,
>> "!file!" echo     letterSpacing: 0.4,
>> "!file!" echo   ^);
>> "!file!" echo   static const TextStyle bodySmallItalic = TextStyle(
>> "!file!" echo     fontSize: 12,
>> "!file!" echo     fontWeight: FontWeight.w400,
>> "!file!" echo     height: 16 / 12,
>> "!file!" echo     letterSpacing: 0.4,
>> "!file!" echo     fontStyle: FontStyle.italic,
>> "!file!" echo   ^);
>> "!file!" echo.
>> "!file!" echo   // ───────────────────── Labels ─────────────────────
>> "!file!" echo   static const TextStyle labelLarge = TextStyle(
>> "!file!" echo     fontSize: 14,
>> "!file!" echo     fontWeight: FontWeight.w700,
>> "!file!" echo     height: 20 / 14,
>> "!file!" echo     letterSpacing: 0.1,
>> "!file!" echo   ^);
>> "!file!" echo   static const TextStyle labelLargeItalic = TextStyle(
>> "!file!" echo     fontSize: 14,
>> "!file!" echo     fontWeight: FontWeight.w700,
>> "!file!" echo     height: 20 / 14,
>> "!file!" echo     letterSpacing: 0.1,
>> "!file!" echo     fontStyle: FontStyle.italic,
>> "!file!" echo   ^);
>> "!file!" echo.
>> "!file!" echo   static const TextStyle labelMedium = TextStyle(
>> "!file!" echo     fontSize: 12,
>> "!file!" echo     fontWeight: FontWeight.w600,
>> "!file!" echo     height: 16 / 12,
>> "!file!" echo     letterSpacing: 0.5,
>> "!file!" echo   ^);
>> "!file!" echo   static const TextStyle labelMediumItalic = TextStyle(
>> "!file!" echo     fontSize: 12,
>> "!file!" echo     fontWeight: FontWeight.w600,
>> "!file!" echo     height: 16 / 12,
>> "!file!" echo     letterSpacing: 0.5,
>> "!file!" echo     fontStyle: FontStyle.italic,
>> "!file!" echo   ^);
>> "!file!" echo.
>> "!file!" echo   static const TextStyle labelSmall = TextStyle(
>> "!file!" echo     fontSize: 11,
>> "!file!" echo     fontWeight: FontWeight.w600,
>> "!file!" echo     height: 16 / 11,
>> "!file!" echo     letterSpacing: 0.5,
>> "!file!" echo   ^);
>> "!file!" echo   static const TextStyle labelSmallItalic = TextStyle(
>> "!file!" echo     fontSize: 11,
>> "!file!" echo     fontWeight: FontWeight.w600,
>> "!file!" echo     height: 16 / 11,
>> "!file!" echo     letterSpacing: 0.5,
>> "!file!" echo     fontStyle: FontStyle.italic,
>> "!file!" echo   ^);
>> "!file!" echo.
>> "!file!" echo   // ───────────────────── Buttons ─────────────────────
>> "!file!" echo   static const TextStyle buttonPrimary = TextStyle(
>> "!file!" echo     fontSize: 14,
>> "!file!" echo     fontWeight: FontWeight.w700,
>> "!file!" echo     height: 20 / 14,
>> "!file!" echo     letterSpacing: 0.75,
>> "!file!" echo     color: Colors.white,
>> "!file!" echo   ^);
>> "!file!" echo   static const TextStyle buttonPrimaryItalic = TextStyle(
>> "!file!" echo     fontSize: 14,
>> "!file!" echo     fontWeight: FontWeight.w700,
>> "!file!" echo     height: 20 / 14,
>> "!file!" echo     letterSpacing: 0.75,
>> "!file!" echo     color: Colors.white,
>> "!file!" echo     fontStyle: FontStyle.italic,
>> "!file!" echo   ^);
>> "!file!" echo.
>> "!file!" echo   static const TextStyle buttonSecondary = TextStyle(
>> "!file!" echo     fontSize: 14,
>> "!file!" echo     fontWeight: FontWeight.w600,
>> "!file!" echo     height: 20 / 14,
>> "!file!" echo     letterSpacing: 0.75,
>> "!file!" echo   ^);
>> "!file!" echo   static const TextStyle buttonSecondaryItalic = TextStyle(
>> "!file!" echo     fontSize: 14,
>> "!file!" echo     fontWeight: FontWeight.w600,
>> "!file!" echo     height: 20 / 14,
>> "!file!" echo     letterSpacing: 0.75,
>> "!file!" echo     fontStyle: FontStyle.italic,
>> "!file!" echo   ^);
>> "!file!" echo.
>> "!file!" echo   // ───────────────────── Captions ^& Overline ─────────────────────
>> "!file!" echo   static const TextStyle caption = TextStyle(
>> "!file!" echo     fontSize: 11,
>> "!file!" echo     fontWeight: FontWeight.w400,
>> "!file!" echo     height: 16 / 11,
>> "!file!" echo     letterSpacing: 0.5,
>> "!file!" echo     color: Colors.grey,
>> "!file!" echo   ^);
>> "!file!" echo }
set "file=!repo_root!\lib\core\utils\app_key_store.dart"
> "!file!" echo abstract final class AppKeyStore { static const themeMode = 'theme_mode'; static const onboardingAccepted = 'onboarding_accepted'; }
set "file=!repo_root!\lib\core\routing\guards\onboarding_redirect.dart"
> "!file!" echo import 'package:flutter/widgets.dart';
>> "!file!" echo import 'package:get/get.dart';
>> "!file!" echo import 'package:go_router/go_router.dart';
>> "!file!" echo import 'package:shared_preferences/shared_preferences.dart';
>> "!file!" echo import 'package:!flutter_project_name!/core/routing/app_route.dart';
>> "!file!" echo import 'package:!flutter_project_name!/core/utils/app_key_store.dart';
>> "!file!" echo String? redirectOnboardingGuard(BuildContext context, GoRouterState state) {
>> "!file!" echo   final preferences = Get.find^<SharedPreferences^>();
>> "!file!" echo   final hasAcceptedOnboarding = preferences.getBool(AppKeyStore.onboardingAccepted) ?? false;
>> "!file!" echo   final isOnboardingRoute = state.matchedLocation == AppRoute.onboarding.path;
>> "!file!" echo   if (^!hasAcceptedOnboarding ^&^& ^!isOnboardingRoute) return AppRoute.onboarding.path;
>> "!file!" echo   if (hasAcceptedOnboarding ^&^& isOnboardingRoute) return AppRoute.home.path;
>> "!file!" echo   return null;
>> "!file!" echo }
set "file=!repo_root!\lib\core\utils\extensions.dart"
> "!file!" echo import 'package:flutter/widgets.dart';
>> "!file!" echo extension BuildContextScreenSize on BuildContext { Size get screenSize =^> MediaQuery.sizeOf(this); }

set "file=!repo_root!\lib\core\view\domain\repositories\theme_repository.dart"
> "!file!" echo import 'package:flutter/material.dart';
>> "!file!" echo abstract interface class ThemeRepository { Future^<ThemeMode^> getThemeMode(); Future^<void^> saveThemeMode(ThemeMode mode); }
set "file=!repo_root!\lib\core\view\domain\use_cases\get_theme_mode.dart"
> "!file!" echo import 'package:flutter/material.dart';
>> "!file!" echo import 'package:!flutter_project_name!/core/view/domain/repositories/theme_repository.dart';
>> "!file!" echo class GetThemeModeUseCase {
>> "!file!" echo   const GetThemeModeUseCase(this._repository);
>> "!file!" echo   final ThemeRepository _repository;
>> "!file!" echo   Future^<ThemeMode^> call() =^> _repository.getThemeMode();
>> "!file!" echo }
set "file=!repo_root!\lib\core\view\domain\use_cases\set_theme_mode.dart"
> "!file!" echo import 'package:flutter/material.dart';
>> "!file!" echo import 'package:!flutter_project_name!/core/view/domain/repositories/theme_repository.dart';
>> "!file!" echo class SetThemeModeUseCase {
>> "!file!" echo   const SetThemeModeUseCase(this._repository);
>> "!file!" echo   final ThemeRepository _repository;
>> "!file!" echo   Future^<void^> call(ThemeMode mode) =^> _repository.saveThemeMode(mode);
>> "!file!" echo }
set "file=!repo_root!\lib\core\view\data\repo_impl\theme_repository_shared_prefs_impl.dart"
> "!file!" echo import 'package:flutter/material.dart';
>> "!file!" echo import 'package:shared_preferences/shared_preferences.dart';
>> "!file!" echo import 'package:!flutter_project_name!/core/utils/app_key_store.dart';
>> "!file!" echo import 'package:!flutter_project_name!/core/view/domain/repositories/theme_repository.dart';
>> "!file!" echo class ThemeRepositorySharedPrefsImpl implements ThemeRepository {
>> "!file!" echo   const ThemeRepositorySharedPrefsImpl(this._preferences);
>> "!file!" echo   final SharedPreferences _preferences;
>> "!file!" echo   @override
>> "!file!" echo   Future^<ThemeMode^> getThemeMode() async =^> ThemeMode.values.byName(_preferences.getString(AppKeyStore.themeMode) ?? ThemeMode.system.name);
>> "!file!" echo   @override
>> "!file!" echo   Future^<void^> saveThemeMode(ThemeMode mode) async { await _preferences.setString(AppKeyStore.themeMode, mode.name); }
>> "!file!" echo }
set "file=!repo_root!\lib\core\view\controllers\theme_controller.dart"
> "!file!" echo import 'package:flutter/material.dart';
>> "!file!" echo import 'package:get/get.dart';
>> "!file!" echo import 'package:!flutter_project_name!/core/view/domain/use_cases/get_theme_mode.dart';
>> "!file!" echo import 'package:!flutter_project_name!/core/view/domain/use_cases/set_theme_mode.dart';
>> "!file!" echo class ThemeController extends GetxController {
>> "!file!" echo   ThemeController({required GetThemeModeUseCase getThemeMode, required SetThemeModeUseCase setThemeModeUseCase}) : _getThemeMode = getThemeMode, _setThemeMode = setThemeModeUseCase;
>> "!file!" echo   final GetThemeModeUseCase _getThemeMode;
>> "!file!" echo   final SetThemeModeUseCase _setThemeMode;
>> "!file!" echo   final themeMode = ThemeMode.system.obs;
>> "!file!" echo   @override
>> "!file!" echo   void onInit() { super.onInit(); _loadThemeMode(); }
>> "!file!" echo   Future^<void^> _loadThemeMode() async { themeMode.value = await _getThemeMode(); }
>> "!file!" echo   Future^<void^> setThemeMode(ThemeMode mode) async { themeMode.value = mode; await _setThemeMode(mode); }
>> "!file!" echo }

set "file=!repo_root!\l10n.yaml"
> "!file!" echo arb-dir: lib/l10n
>> "!file!" echo template-arb-file: app_it.arb
>> "!file!" echo output-localization-file: app_localizations.dart
>> "!file!" echo output-class: AppLocalizations
>> "!file!" echo nullable-getter: false

set "file=!repo_root!\lib\l10n\app_en.arb"
> "!file!" echo {
>> "!file!" echo   "@@locale": "en",
>> "!file!" echo   "appTitle": "App"
>> "!file!" echo }
set "file=!repo_root!\lib\l10n\app_it.arb"
> "!file!" echo {
>> "!file!" echo   "@@locale": "it",
>> "!file!" echo   "appTitle": "App"
>> "!file!" echo }

for %%E in (!environment_names!) do (
  mkdir "!repo_root!\lib\entrypoints\%%E" >nul 2>nul
  set "file=!repo_root!\lib\entrypoints\%%E\main.dart"
  > "!file!" echo import 'package:flutter/material.dart';
  >> "!file!" echo import 'package:!flutter_project_name!/app.dart';
  >> "!file!" echo import 'package:!flutter_project_name!/core/config/app_config.dart';
  >> "!file!" echo Future^<void^> main() async {
  >> "!file!" echo   WidgetsFlutterBinding.ensureInitialized();
  >> "!file!" echo   const config = AppConfig(environment: '%%E', displayName: '!app_display_name!', baseUrl: 'http://localhost:8080', routerShape: '!router_shape!');
  >> "!file!" echo   await bootstrapApp(config: config);
  >> "!file!" echo }
)

echo Architecture scaffold created.
exit /b 0

:run_ide_config
if not defined repo_root (
  echo IDE config step failed: repository root is not available.
  exit /b 1
)

echo ide_config
set "VSCODE_DIR=!repo_root!\.vscode"
mkdir "!VSCODE_DIR!" >nul 2>nul

set "LAUNCH_JSON_PATH=!VSCODE_DIR!\launch.json"
set "ENVIRONMENT_NAMES=!environment_names!"
echo Writing: !LAUNCH_JSON_PATH!
powershell -NoProfile -ExecutionPolicy Bypass -Command "$path=$env:LAUNCH_JSON_PATH; $envs=$env:ENVIRONMENT_NAMES -split '\s+' | Where-Object { $_ }; $configs=@(); foreach($envName in $envs){ $configs += [ordered]@{ name='Flutter ' + $envName; request='launch'; type='dart'; program='lib/entrypoints/' + $envName + '/main.dart' } }; $root=[ordered]@{ version='0.2.0'; configurations=$configs }; $root | ConvertTo-Json -Depth 5 | Set-Content -Path $path -Encoding utf8"
if errorlevel 1 (
  echo IDE config step failed while writing .vscode\launch.json.
  exit /b 1
)

if exist "!repo_root!\.idea" (
  set "RUN_CONFIG_DIR=!repo_root!\.idea\runConfigurations"
  mkdir "!RUN_CONFIG_DIR!" >nul 2>nul
  for %%E in (!environment_names!) do (
    call :sanitize_snake_case "flutter_%%E" run_config_name
    set "RUN_CONFIG_PATH=!RUN_CONFIG_DIR!\!run_config_name!.xml"
    echo Writing: !RUN_CONFIG_PATH!
    > "!RUN_CONFIG_PATH!" echo ^<component name="ProjectRunConfigurationManager"^>
    >> "!RUN_CONFIG_PATH!" echo   ^<configuration default="false" name="Flutter %%E" type="FlutterRunConfigurationType" factoryName="Flutter"^>
    >> "!RUN_CONFIG_PATH!" echo     ^<option name="filePath" value="$PROJECT_DIR$/lib/entrypoints/%%E/main.dart" /^>
    >> "!RUN_CONFIG_PATH!" echo     ^<method v="2" /^>
    >> "!RUN_CONFIG_PATH!" echo   ^</configuration^>
    >> "!RUN_CONFIG_PATH!" echo ^</component^>
  )
) else (
  echo JetBrains config skipped: .idea directory not present.
)

echo IDE run configurations created.
exit /b 0

:run_validation
if not defined repo_root (
  echo Validation step failed: repository root is not available.
  exit /b 1
)

if not exist "!repo_root!\pubspec.yaml" (
  echo Validation step failed: pubspec.yaml was not found in the repository root.
  exit /b 1
)

echo validation
pushd "!repo_root!" >nul
if errorlevel 1 (
  echo Validation step failed: unable to enter the repository root.
  exit /b 1
)

echo Running: fvm flutter pub get
call fvm flutter pub get
if errorlevel 1 (
  popd >nul
  echo Validation step failed while running fvm flutter pub get.
  exit /b 1
)

echo Running: fvm flutter analyze
call fvm flutter analyze
if errorlevel 1 (
  popd >nul
  echo Validation step failed while running fvm flutter analyze.
  exit /b 1
)

popd >nul
echo Validation completed successfully.
exit /b 0

:run_cleanup
if not defined temp_directory exit /b 0
if not exist "!temp_directory!" (
  set "temp_directory="
  exit /b 0
)

echo cleanup
echo Removing temporary workspace: !temp_directory!
rmdir /S /Q "!temp_directory!"
if errorlevel 1 (
  echo Cleanup step failed while removing the temporary workspace.
  exit /b 1
)

set "temp_directory="
echo Temporary workspace removed.
exit /b 0

:prompt_input
set "input_name=%~1"

if /i "%input_name%"=="project_name" (
  call :prompt_text project_name project_name
  exit /b 0
)

if /i "%input_name%"=="app_display_name" (
  call :prompt_text app_display_name app_display_name
  exit /b 0
)

if /i "%input_name%"=="target_platforms" (
  call :prompt_platforms target_platforms
  exit /b 0
)

if /i "%input_name%"=="environment_names" (
  call :prompt_environments environment_names
  exit /b 0
)

if /i "%input_name%"=="router_shape" (
  call :prompt_router_shape router_shape
  exit /b 0
)

call :prompt_text %input_name% %input_name%
exit /b 0

:prompt_text
set "var_name=%~1"
set "label=%~2"

:prompt_text_loop
set "value="
set /p "value=%label%: "
if not defined value (
  echo Value cannot be empty. Please try again.
  goto :prompt_text_loop
)
set "%var_name%=%value%"
exit /b 0

:prompt_platforms
set "var_name=%~1"
call :prompt_checkbox "%var_name%" "target_platforms" "1" "android;ios;web;macos;windows;linux"
exit /b 0

:prompt_environments
set "var_name=%~1"
call :prompt_checkbox "%var_name%" "environment_names" "2" "dev;test;prod"
exit /b 0

:prompt_checkbox
set "checkbox_var_name=%~1"
set "CHECKBOX_TITLE=%~2"
set "CHECKBOX_MINIMUM=%~3"
set "CHECKBOX_OPTIONS=%~4"
set "checkbox_result="
for /f "usebackq delims=" %%S in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%script_dir%checkbox_prompt.ps1"`) do set "checkbox_result=%%S"
if errorlevel 1 exit /b 1
if not defined checkbox_result exit /b 1
set "%checkbox_var_name%=%checkbox_result%"
exit /b 0

:prompt_router_shape
set "var_name=%~1"

:prompt_router_shape_loop
set "value="
set /p "value=router_shape: "
if /i "%value%"=="root" (
  set "%var_name%=root"
  exit /b 0
)
if /i "%value%"=="shell" (
  set "%var_name%=shell"
  exit /b 0
)
echo Please enter either 'root' or 'shell'.
goto :prompt_router_shape_loop

:detect_flutter_project
set "repo_root=%~1"
set "has_pubspec=0"
set "has_other_flutter_signals=0"

if exist "%repo_root%\pubspec.yaml" (
  set "has_pubspec=1"
  findstr /R /C:"^[ ]*flutter:[ ]*$" "%repo_root%\pubspec.yaml" >nul && exit /b 1
)

if exist "%repo_root%\lib" set "has_other_flutter_signals=1"
if exist "%repo_root%\android" set "has_other_flutter_signals=1"
if exist "%repo_root%\ios" set "has_other_flutter_signals=1"
if exist "%repo_root%\analysis_options.yaml" set "has_other_flutter_signals=1"
if exist "%repo_root%\test" set "has_other_flutter_signals=1"
if exist "%repo_root%\web" set "has_other_flutter_signals=1"
if exist "%repo_root%\windows" set "has_other_flutter_signals=1"
if exist "%repo_root%\macos" set "has_other_flutter_signals=1"
if exist "%repo_root%\linux" set "has_other_flutter_signals=1"

if "%has_pubspec%"=="1" if "%has_other_flutter_signals%"=="1" exit /b 1
if "%has_pubspec%"=="0" if "%has_other_flutter_signals%"=="1" exit /b 2

exit /b 0

:classify_placeholder_file
set "file_path=%~1"
set "result=missing"

if exist "%file_path%" (
  for %%F in ("%file_path%") do (
    if %%~zF EQU 0 (
      set "result=placeholder (empty)"
    ) else if /i "%%~nxF"=="README.md" (
      findstr /I /C:"A new Flutter project" /C:"Getting Started" /C:"Flutter" "%file_path%" >nul && (
        set "result=likely placeholder"
      ) || (
        set "result=custom, preserve"
      )
    ) else if /i "%%~nxF"==".gitignore" (
      findstr /I /C:".dart_tool/" /C:"build/" /C:"Generated file" /C:"Flutter" "%file_path%" >nul && (
        set "result=likely placeholder"
      ) || (
        set "result=custom, preserve"
      )
    ) else if /i "%%~nxF"=="LICENSE" (
      findstr /I /C:"copyright" /C:"bsd" /C:"mit" /C:"apache" "%file_path%" >nul && (
        set "result=license file or custom content"
      ) || (
        set "result=custom, preserve"
      )
    ) else (
      set "result=unknown"
    )
  )
)

set "%~2=%result%"
exit /b 0

:derive_values
call :sanitize_snake_case "%project_name%" flutter_project_name
call :sanitize_platform_name "%project_name%" platform_name
set "platform_identifier_base=it.alessandrorondolini.!platform_name!"
exit /b 0

:create_temp_workspace
if defined TMP (
  set "temp_base=!TMP!"
) else if defined TEMP (
  set "temp_base=!TEMP!"
) else (
  set "temp_base=C:\Temp"
)
set "temp_directory=!temp_base!\flutter-bootstrap-!RANDOM!!RANDOM!"
mkdir "!temp_directory!" >nul 2>nul
if errorlevel 1 (
  echo Preflight error: unable to create temp workspace: !temp_directory!
  exit /b 1
)
exit /b 0

:sanitize_snake_case
set "input=%~1"
call :to_lower "%input%" lowered
set "result="
set "need_sep=0"

:sanitize_snake_case_loop
if not defined lowered goto sanitize_snake_case_done
set "ch=!lowered:~0,1!"
set "lowered=!lowered:~1!"
call :is_alnum "!ch!" is_alnum
if "!is_alnum!"=="1" (
  if defined result if "!need_sep!"=="1" set "result=!result!_"
  set "result=!result!!ch!"
  set "need_sep=0"
) else (
  if defined result set "need_sep=1"
)
goto sanitize_snake_case_loop

:sanitize_snake_case_done
if not defined result set "result=app"
set "first=!result:~0,1!"
for %%D in (0 1 2 3 4 5 6 7 8 9) do if "!first!"=="%%D" set "result=app_!result!"
set "%~2=%result%"
exit /b 0

:sanitize_platform_name
set "input=%~1"
call :to_lower "%input%" lowered
set "result="

:sanitize_platform_name_loop
if not defined lowered goto sanitize_platform_name_done
set "ch=!lowered:~0,1!"
set "lowered=!lowered:~1!"
call :is_alnum "!ch!" is_alnum
if "!is_alnum!"=="1" set "result=!result!!ch!"
goto sanitize_platform_name_loop

:sanitize_platform_name_done
if not defined result set "result=app"
set "first=!result:~0,1!"
for %%D in (0 1 2 3 4 5 6 7 8 9) do if "!first!"=="%%D" set "result=app!result!"
set "%~2=%result%"
exit /b 0

:pascal_case
set "input=%~1"
call :sanitize_snake_case "%input%" snake_value
set "result="

:pascal_case_loop
if not defined snake_value goto pascal_case_done
for /f "tokens=1* delims=_" %%A in ("!snake_value!") do (
  set "part=%%A"
  set "snake_value=%%B"
)
if defined part (
  set "first=!part:~0,1!"
  set "rest=!part:~1!"
  call :to_upper "!first!" upper_first
  set "result=!result!!upper_first!!rest!"
)
goto pascal_case_loop

:pascal_case_done
if not defined result set "result=App"
set "first=!result:~0,1!"
for %%D in (0 1 2 3 4 5 6 7 8 9) do if "!first!"=="%%D" set "result=App!result!"
set "%~2=%result%"
exit /b 0

:to_lower
set "value=%~1"
set "value=%value:A=a%"
set "value=%value:B=b%"
set "value=%value:C=c%"
set "value=%value:D=d%"
set "value=%value:E=e%"
set "value=%value:F=f%"
set "value=%value:G=g%"
set "value=%value:H=h%"
set "value=%value:I=i%"
set "value=%value:J=j%"
set "value=%value:K=k%"
set "value=%value:L=l%"
set "value=%value:M=m%"
set "value=%value:N=n%"
set "value=%value:O=o%"
set "value=%value:P=p%"
set "value=%value:Q=q%"
set "value=%value:R=r%"
set "value=%value:S=s%"
set "value=%value:T=t%"
set "value=%value:U=u%"
set "value=%value:V=v%"
set "value=%value:W=w%"
set "value=%value:X=x%"
set "value=%value:Y=y%"
set "value=%value:Z=z%"
set "%~2=%value%"
exit /b 0

:to_upper
set "value=%~1"
set "value=%value:a=A%"
set "value=%value:b=B%"
set "value=%value:c=C%"
set "value=%value:d=D%"
set "value=%value:e=E%"
set "value=%value:f=F%"
set "value=%value:g=G%"
set "value=%value:h=H%"
set "value=%value:i=I%"
set "value=%value:j=J%"
set "value=%value:k=K%"
set "value=%value:l=L%"
set "value=%value:m=M%"
set "value=%value:n=N%"
set "value=%value:o=O%"
set "value=%value:p=P%"
set "value=%value:q=Q%"
set "value=%value:r=R%"
set "value=%value:s=S%"
set "value=%value:t=T%"
set "value=%value:u=U%"
set "value=%value:v=V%"
set "value=%value:w=W%"
set "value=%value:x=X%"
set "value=%value:y=Y%"
set "value=%value:z=Z%"
set "%~2=%value%"
exit /b 0

:is_alnum
set "char=%~1"
set "flag=0"
for %%D in (0 1 2 3 4 5 6 7 8 9) do if "%char%"=="%%D" set "flag=1"
for %%L in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do if /i "%char%"=="%%L" set "flag=1"
set "%~2=%flag%"
exit /b 0
