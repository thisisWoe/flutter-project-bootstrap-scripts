import 'dart:convert';
import 'dart:io';
import 'dart:math';

typedef BootstrapLogCallback = void Function(String message);

class BootstrapRequest {
  const BootstrapRequest({
    required this.targetRoot,
    required this.projectName,
    required this.appDisplayName,
    required this.organizationId,
    required this.targetPlatforms,
    required this.environmentNames,
    required this.routerShape,
  });

  final String targetRoot;
  final String projectName;
  final String appDisplayName;
  final String organizationId;
  final List<String> targetPlatforms;
  final List<String> environmentNames;
  final String routerShape;
}

class BootstrapFailure implements Exception {
  const BootstrapFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class BootstrapService {
  const BootstrapService();

  static const defaultOrganizationId = 'it.alessandrorondolini';
  static const _runtimeDependencies = <String>[
    'dio',
    'shared_preferences',
    'get',
    'go_router',
    'intl',
    'flutter_displaymode',
    'stack_trace',
    'skeletonizer',
    'url_launcher',
    'device_info_plus',
    'package_info_plus',
  ];
  static const _devDependencies = <String>[
    'flutter_native_splash',
    'flutter_launcher_icons',
    'flutter_lints',
  ];
  static const _architectureDirectories = <String>[
    'lib/core/bindings',
    'lib/core/config',
    'lib/core/network',
    'lib/core/routing',
    'lib/core/routing/guards',
    'lib/core/shared_preferences/data/repo_impl',
    'lib/core/shared_preferences/domain/repositories',
    'lib/core/styles',
    'lib/core/utils',
    'lib/core/view/controllers',
    'lib/core/view/data/repo_impl',
    'lib/core/view/domain/repositories',
    'lib/core/view/domain/use_cases',
    'lib/core/view/widgets',
    'lib/features/onboarding/view/bindings',
    'lib/features/onboarding/view/controllers',
    'lib/features/onboarding/view/pages',
    'lib/features/onboarding/view/widgets',
    'lib/features/onboarding/data/models',
    'lib/features/onboarding/data/repo_impl',
    'lib/features/onboarding/domain/entities',
    'lib/features/onboarding/domain/repositories',
    'lib/features/onboarding/domain/use_cases',
    'lib/features/home/view/bindings',
    'lib/features/home/view/controllers',
    'lib/features/home/view/pages',
    'lib/features/home/view/widgets',
    'lib/features/home/data/models',
    'lib/features/home/data/repo_impl',
    'lib/features/home/domain/entities',
    'lib/features/home/domain/repositories',
    'lib/features/home/domain/use_cases',
    'lib/features/profile/view/bindings',
    'lib/features/profile/view/controllers',
    'lib/features/profile/view/pages',
    'lib/features/profile/view/widgets',
    'lib/features/profile/data/models',
    'lib/features/profile/data/repo_impl',
    'lib/features/profile/domain/entities',
    'lib/features/profile/domain/repositories',
    'lib/features/profile/domain/use_cases',
    'lib/l10n',
  ];

  Future<void> run(
    BootstrapRequest request, {
    BootstrapLogCallback? onLog,
  }) async {
    final session = _BootstrapSession(request: request, onLog: onLog);
    await session.run();
  }
}

class _BootstrapSession {
  _BootstrapSession({required this.request, this.onLog});

  final BootstrapRequest request;
  final BootstrapLogCallback? onLog;

  late final String projectName = _trim(request.projectName);
  late final String appDisplayName = _trim(request.appDisplayName);
  late final String organizationId = _trim(request.organizationId);
  late final List<String> targetPlatforms = request.targetPlatforms
      .map(_trim)
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  late final List<String> environmentNames = request.environmentNames
      .map(_trim)
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  late final String routerShape = _trim(request.routerShape);
  late final String flutterProjectName = _sanitizeSnakeCase(projectName);
  late final String platformName = _sanitizePlatformName(projectName);
  late final String platformIdentifierBase = '$organizationId.$platformName';
  late final String appClassName = '${_pascalCase(flutterProjectName)}App';

  String? repoRoot;
  String? tempDirectory;
  String? templatesRoot;

  Future<void> run() async {
    try {
      await _runPreflight(request.targetRoot);

      _log('Bootstrap input collector');
      _log(
        'Required inputs: project_name, app_display_name, target_platforms, environment_names, router_shape',
      );
      _log('');
      _log('Collected values');
      _log('project_name: $projectName');
      _log('app_display_name: $appDisplayName');
      _log('organization_id: $organizationId');
      _log('target_platforms: [${targetPlatforms.join(' ')}]');
      _log('environment_names: [${environmentNames.join(' ')}]');
      _log('router_shape: $routerShape');
      _log('');
      _log('derived_values');
      _log('flutter_project_name: $flutterProjectName');
      _log('platform_identifier_base: $platformIdentifierBase');
      _log('android_namespace: $platformIdentifierBase');
      _log('android_application_id: $platformIdentifierBase');
      _log('ios_bundle_identifier: $platformIdentifierBase');

      tempDirectory = await _createTempWorkspace();
      _log('temp_directory: $tempDirectory');
      _log('');
      _log('Temp workspace');
      _log('Created temp directory: $tempDirectory');
      _log('');

      await _runFvmSetup();
      _log('');
      _confirmAppleRenameReadiness();
      await _runCreateFlutterApp();
      await _removeTransientFvmFilesFromTemp();
      await _runCopyIntoRepo();
      await _runAddDependencies();
      await _runAnalysisOptions();
      await _runArchitectureScaffold();
      await _runIdeConfig();
      await _runValidation();
    } finally {
      await _runCleanup();
    }
  }

  void _log(String message) {
    onLog?.call(message);
  }

  Never _fail(String message) {
    _log(message);
    throw BootstrapFailure(message);
  }

  String _joinPath(
    String first, [
    String? second,
    String? third,
    String? fourth,
    String? fifth,
    String? sixth,
    String? seventh,
  ]) {
    final parts = <String>[
      first,
      for (final part in <String?>[
        second,
        third,
        fourth,
        fifth,
        sixth,
        seventh,
      ].whereType<String>())
        part,
    ];
    return parts.join(Platform.pathSeparator);
  }

  Future<String> _renderTemplateFile(String relativePath) async {
    final root = await _resolveTemplatesRoot();
    final templatePath = [
      root,
      ...relativePath.split('/'),
    ].join(Platform.pathSeparator);
    final templateFile = File(templatePath);
    if (!await templateFile.exists()) {
      _fail('Template render failed: template was not found: $templatePath');
    }

    var contents = await templateFile.readAsString();
    contents = contents.replaceAll('__PROJECT_NAME__', flutterProjectName);
    return contents;
  }

  Future<String> _resolveTemplatesRoot() async {
    if (templatesRoot != null) {
      return templatesRoot!;
    }

    final candidateRoots = <String>[];

    void addCandidate(String path) {
      if (path.isEmpty || candidateRoots.contains(path)) {
        return;
      }
      candidateRoots.add(path);
    }

    void addDirectoryAndParents(String path) {
      var current = Directory(path).absolute;
      while (true) {
        addCandidate(current.path);
        final parent = current.parent;
        if (parent.path == current.path) {
          break;
        }
        current = parent;
      }
    }

    addDirectoryAndParents(Directory.current.path);
    addDirectoryAndParents(File(Platform.resolvedExecutable).parent.path);

    if (Platform.script.scheme == 'file') {
      addDirectoryAndParents(File.fromUri(Platform.script).parent.path);
    }

    for (final root in candidateRoots) {
      final templateFile = File(
        _joinPath(
          root,
          'templates',
          'lib',
          'core',
          'styles',
          'app_colors.dart.tpl',
        ),
      );
      if (await templateFile.exists()) {
        templatesRoot = _joinPath(root, 'templates');
        return templatesRoot!;
      }
    }

    _fail(
      'Template discovery failed: unable to locate the repository templates directory.',
    );
  }

  String _trim(String value) {
    return value.trim();
  }

  String _sanitizeSnakeCase(String value) {
    var sanitized = value.toLowerCase().replaceAll(
      RegExp(r'[^A-Za-z0-9]+'),
      '_',
    );
    sanitized = sanitized.replaceAll(RegExp(r'^_+|_+$'), '');
    if (sanitized.isEmpty) {
      sanitized = 'app';
    }
    if (RegExp(r'^[0-9]').hasMatch(sanitized)) {
      sanitized = 'app_$sanitized';
    }
    return sanitized;
  }

  String _sanitizePlatformName(String value) {
    var sanitized = value.toLowerCase().replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (sanitized.isEmpty) {
      sanitized = 'app';
    }
    if (RegExp(r'^[0-9]').hasMatch(sanitized)) {
      sanitized = 'app$sanitized';
    }
    return sanitized;
  }

  String _pascalCase(String value) {
    var normalized = value.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    normalized = normalized.replaceAll(RegExp(r'^_+|_+$'), '');
    final parts = normalized.split('_').where((part) => part.isNotEmpty);
    final buffer = StringBuffer();
    for (final part in parts) {
      buffer.write(part[0].toUpperCase());
      buffer.write(part.substring(1));
    }
    var result = buffer.toString();
    if (result.isEmpty) {
      result = 'App';
    }
    if (RegExp(r'^[0-9]').hasMatch(result)) {
      result = 'App$result';
    }
    return result;
  }

  Future<String> _createTempWorkspace() async {
    final candidate = _joinPath(
      Directory.systemTemp.path,
      'flutter-bootstrap-$pid-${Random().nextInt(1 << 32)}',
    );
    final directory = Directory(candidate);
    await directory.create(recursive: true);
    return directory.path;
  }

  Future<void> _runPreflight(String inputRoot) async {
    final inputDirectory = Directory(
      _trim(inputRoot).isEmpty ? Directory.current.path : inputRoot,
    );
    if (!await inputDirectory.exists()) {
      _fail(
        'Preflight error: target path does not exist: ${inputDirectory.path}',
      );
    }

    final targetRoot = await _canonicalDirectoryPath(inputDirectory);
    repoRoot = targetRoot;

    _log('Preflight');
    _log('Target root: $targetRoot');

    final gitRoot = await _tryGetGitRoot(targetRoot);
    if (gitRoot != null) {
      _log('Git repository detected: $gitRoot');
    } else {
      _log('Git repository: not detected');
    }

    var issueCount = 0;
    if (await _detectFlutterProject(targetRoot)) {
      _log('Issue: existing Flutter project detected. Bootstrap must stop.');
      issueCount++;
    } else {
      _log('Flutter project detection: no coherent Flutter scaffold found');
    }

    if (!await File(_joinPath(targetRoot, 'pubspec.yaml')).exists() &&
        await _hasFlutterSignals(targetRoot)) {
      _log(
        'Issue: isolated Flutter-related files detected; target directory requires manual review.',
      );
      issueCount++;
    }

    _log('Placeholder scan');
    _log(
      'README.md: ${await _classifyPlaceholderFile(_joinPath(targetRoot, 'README.md'))}',
    );
    _log(
      '.gitignore: ${await _classifyPlaceholderFile(_joinPath(targetRoot, '.gitignore'))}',
    );
    _log(
      'LICENSE: ${await _classifyPlaceholderFile(_joinPath(targetRoot, 'LICENSE'))}',
    );

    if (issueCount > 0) {
      _fail('Preflight failed. Fix the issues above before bootstrapping.');
    }

    _log('Preflight OK');
  }

  Future<String> _canonicalDirectoryPath(Directory directory) async {
    try {
      return await directory.resolveSymbolicLinks();
    } catch (_) {
      return directory.absolute.path;
    }
  }

  Future<String?> _tryGetGitRoot(String targetRoot) async {
    try {
      final result = await Process.run('git', [
        '-C',
        targetRoot,
        'rev-parse',
        '--show-toplevel',
      ], runInShell: true);
      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        if (output.isNotEmpty) {
          return output;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<bool> _detectFlutterProject(String root) async {
    final pubspecFile = File(_joinPath(root, 'pubspec.yaml'));
    if (await pubspecFile.exists()) {
      final contents = await pubspecFile.readAsString();
      if (RegExp(
        r'^[ \t]*flutter:[ \t]*$',
        multiLine: true,
      ).hasMatch(contents)) {
        return true;
      }

      if (await Directory(_joinPath(root, 'lib')).exists() ||
          await Directory(_joinPath(root, 'android')).exists() ||
          await Directory(_joinPath(root, 'ios')).exists()) {
        return true;
      }

      if (await File(_joinPath(root, 'analysis_options.yaml')).exists() ||
          await Directory(_joinPath(root, 'test')).exists() ||
          await Directory(_joinPath(root, 'web')).exists() ||
          await Directory(_joinPath(root, 'windows')).exists() ||
          await Directory(_joinPath(root, 'macos')).exists() ||
          await Directory(_joinPath(root, 'linux')).exists()) {
        return true;
      }
    }

    return false;
  }

  Future<bool> _hasFlutterSignals(String root) async {
    return await Directory(_joinPath(root, 'lib')).exists() ||
        await Directory(_joinPath(root, 'android')).exists() ||
        await Directory(_joinPath(root, 'ios')).exists() ||
        await File(_joinPath(root, 'analysis_options.yaml')).exists() ||
        await Directory(_joinPath(root, 'test')).exists() ||
        await Directory(_joinPath(root, 'web')).exists() ||
        await Directory(_joinPath(root, 'windows')).exists() ||
        await Directory(_joinPath(root, 'macos')).exists() ||
        await Directory(_joinPath(root, 'linux')).exists();
  }

  Future<String> _classifyPlaceholderFile(String path) async {
    final file = File(path);
    final name = path.split(Platform.pathSeparator).last;

    if (!await file.exists()) {
      return 'missing';
    }

    final stat = await file.stat();
    if (stat.size == 0) {
      return 'placeholder (empty)';
    }

    final contents = await file.readAsString();
    switch (name) {
      case 'README.md':
        return RegExp(
              r'A new Flutter project|Getting Started|Flutter',
              caseSensitive: false,
            ).hasMatch(contents)
            ? 'likely placeholder'
            : 'custom, preserve';
      case '.gitignore':
        return RegExp(
              r'\.dart_tool/|build/|Generated file|Flutter',
              caseSensitive: false,
            ).hasMatch(contents)
            ? 'likely placeholder'
            : 'custom, preserve';
      case 'LICENSE':
        return RegExp(
              r'copyright|bsd|mit|apache',
              caseSensitive: false,
            ).hasMatch(contents)
            ? 'license file or custom content'
            : 'custom, preserve';
      default:
        return 'unknown';
    }
  }

  Future<void> _runFvmSetup() async {
    _log('Environment diagnostics');
    _log(
      'Platform executable PATH: ${Platform.environment['PATH'] ?? '(missing)'}',
    );
    _log('Platform SHELL: ${Platform.environment['SHELL'] ?? '(missing)'}');

    final fvmPath = await _resolveCommandPath('fvm');
    if (fvmPath == null) {
      _fail(
        'FVM check failed: fvm was not found in PATH.\nInstall FVM first, then rerun this script.',
      );
    }

    _log('FVM setup');
    _log('fvm found at: $fvmPath');
    await _runCommand(
      'Running: fvm install stable',
      'fvm',
      ['install', 'stable'],
      workingDirectory: tempDirectory!,
      failureMessage:
          'FVM setup failed while installing the stable Flutter SDK.',
    );
    await _runCommand(
      'Running: fvm use stable --force --skip-pub-get',
      'fvm',
      ['use', 'stable', '--force', '--skip-pub-get'],
      workingDirectory: tempDirectory!,
      failureMessage:
          'FVM setup failed while selecting the stable Flutter SDK.',
    );
    await _runCommand(
      'Running: fvm flutter --version',
      'fvm',
      ['flutter', '--version'],
      workingDirectory: tempDirectory!,
      failureMessage:
          'FVM setup failed while verifying the Flutter SDK version.',
    );
    _log('FVM stable channel is ready.');
  }

  Future<String?> _resolveCommandPath(String command) async {
    try {
      final result = Platform.isWindows
          ? await Process.run('where', [command], runInShell: true)
          : await _runShellCommandCapture(
              'command -v ${_shellEscape(command)}',
            );
      if (result.exitCode == 0) {
        final lines = LineSplitter.split(
          result.stdout.toString().trim(),
        ).toList();
        if (lines.isNotEmpty) {
          return lines.first;
        }
      }
    } catch (_) {}
    return null;
  }

  void _confirmAppleRenameReadiness() {
    final needsApple =
        targetPlatforms.contains('ios') || targetPlatforms.contains('macos');
    if (!needsApple) {
      return;
    }

    _log('Apple rename check');
    _log('Selected platforms include iOS or macOS.');
    _log(
      'Derived Apple identifiers can be computed deterministically from the requested project name.',
    );

    if (flutterProjectName.isEmpty ||
        organizationId.isEmpty ||
        platformIdentifierBase.isEmpty ||
        appDisplayName.isEmpty) {
      _fail('Apple rename check failed: required derived values are missing.');
    }

    _log('Apple rename check passed.');
  }

  Future<void> _runCreateFlutterApp() async {
    final flutterPlatforms = targetPlatforms.join(',');
    _log('create_flutter_app');
    _log(
      'Running: cd "$tempDirectory" && fvm flutter create --project-name "$flutterProjectName" --org $organizationId --platforms="$flutterPlatforms" .',
    );
    await _runCommand(
      null,
      'fvm',
      [
        'flutter',
        'create',
        '--project-name',
        flutterProjectName,
        '--org',
        organizationId,
        '--platforms=$flutterPlatforms',
        '.',
      ],
      workingDirectory: tempDirectory!,
      failureMessage:
          'Flutter app creation failed inside the temporary workspace.',
    );
    _log('Flutter app scaffold created in the temporary workspace.');
  }

  Future<void> _removeTransientFvmFilesFromTemp() async {
    final transientEntries = <String>['.fvm', '.fvmrc'];
    for (final entry in transientEntries) {
      await _deletePathIfExists(_joinPath(tempDirectory!, entry));
    }
  }

  Future<void> _runCopyIntoRepo() async {
    if (repoRoot == null) {
      _fail('Copy step failed: repository root is not available.');
    }

    _log('copy_into_repo');
    _log('Running: copy temp workspace into "$repoRoot"');
    await _copyDirectoryContents(
      source: Directory(tempDirectory!),
      destination: Directory(repoRoot!),
    );
    _log('Generated scaffold copied into the repository root.');
  }

  Future<void> _copyDirectoryContents({
    required Directory source,
    required Directory destination,
  }) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(followLinks: false)) {
      final name = _fileName(entity.path);
      final targetPath = _joinPath(destination.path, name);
      if (entity is Directory) {
        await _copyDirectoryContents(
          source: entity,
          destination: Directory(targetPath),
        );
      } else if (entity is File) {
        await File(targetPath).parent.create(recursive: true);
        await entity.copy(targetPath);
      } else if (entity is Link) {
        final linkTarget = await entity.target();
        await Link(targetPath).create(linkTarget);
      }
    }
  }

  Future<void> _runAddDependencies() async {
    if (repoRoot == null) {
      _fail('Dependency step failed: repository root is not available.');
    }

    final pubspecPath = _joinPath(repoRoot!, 'pubspec.yaml');
    if (!await File(pubspecPath).exists()) {
      _fail(
        'Dependency step failed: pubspec.yaml was not found in the repository root.',
      );
    }

    _log('dependencies');
    await _runCommand(
      'Running: fvm flutter pub add ${BootstrapService._runtimeDependencies.join(' ')}',
      'fvm',
      ['flutter', 'pub', 'add', ...BootstrapService._runtimeDependencies],
      workingDirectory: repoRoot!,
      failureMessage:
          'Dependency step failed while adding runtime dependencies.',
    );
    await _runCommand(
      'Running: fvm flutter pub add --dev ${BootstrapService._devDependencies.join(' ')}',
      'fvm',
      ['flutter', 'pub', 'add', '--dev', ...BootstrapService._devDependencies],
      workingDirectory: repoRoot!,
      failureMessage: 'Dependency step failed while adding dev dependencies.',
    );
    _log('Runtime and dev dependencies added.');
  }

  Future<void> _runAnalysisOptions() async {
    if (repoRoot == null) {
      _fail('Analysis options step failed: repository root is not available.');
    }

    final pubspecPath = _joinPath(repoRoot!, 'pubspec.yaml');
    if (!await File(pubspecPath).exists()) {
      _fail(
        'Analysis options step failed: pubspec.yaml was not found in the repository root.',
      );
    }

    final analysisOptionsPath = _joinPath(repoRoot!, 'analysis_options.yaml');
    _log('analysis_options');
    _log('Writing: $analysisOptionsPath');
    await _writeFile(analysisOptionsPath, '''
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    avoid_print: false
    prefer_single_quotes: false
    always_declare_return_types: true
''');
    _log('analysis_options.yaml baseline created.');
  }

  Future<void> _runArchitectureScaffold() async {
    if (repoRoot == null) {
      _fail(
        'Architecture scaffold step failed: repository root is not available.',
      );
    }

    final pubspecPath = _joinPath(repoRoot!, 'pubspec.yaml');
    final pubspecFile = File(pubspecPath);
    if (!await pubspecFile.exists()) {
      _fail(
        'Architecture scaffold step failed: pubspec.yaml was not found in the repository root.',
      );
    }

    _log('architecture_scaffold');
    _log(
      'Creating canonical lib/, feature, routing, entrypoint, and localization files.',
    );

    await _ensureFlutterLocalizations(pubspecFile);
    await _ensureFlutterGenerate(pubspecFile);

    for (final relativePath in BootstrapService._architectureDirectories) {
      await Directory(
        _joinPath(repoRoot!, relativePath),
      ).create(recursive: true);
    }

    await _removeGeneratedFlutterScaffoldArtifacts();

    final appColorsTemplate = await _renderTemplateFile(
      'lib/core/styles/app_colors.dart.tpl',
    );
    final appBaseThemeTemplate = await _renderTemplateFile(
      'lib/core/styles/app_base_theme.dart.tpl',
    );

    final scaffoldFiles = <String, String>{
      _joinPath(repoRoot!, 'lib', 'core', 'config', 'app_config.dart'):
          _appConfigDart(),
      _joinPath(repoRoot!, 'lib', 'core', 'network', 'dio.dart'): _dioDart(),
      _joinPath(repoRoot!, 'lib', 'core', 'bindings', 'core_bindings.dart'):
          _coreBindingsDart(),
      _joinPath(repoRoot!, 'lib', 'app.dart'): _appDart(),
      _joinPath(repoRoot!, 'lib', 'core', 'routing', 'app_route.dart'):
          _appRouteDart(),
      _joinPath(repoRoot!, 'lib', 'core', 'routing', 'go_router_observer.dart'):
          _goRouterObserverDart(),
      _joinPath(repoRoot!, 'lib', 'core', 'routing', 'routes.dart'):
          _routesDart(),
      _joinPath(repoRoot!, 'lib', 'core', 'routing', 'shell_routes.dart'):
          _shellRoutesDart(),
      _joinPath(repoRoot!, 'lib', 'core', 'view', 'widgets', 'app_shell.dart'):
          _appShellDart(),
      _joinPath(repoRoot!, 'lib', 'core', 'styles', 'app_colors.dart'):
          appColorsTemplate,
      _joinPath(repoRoot!, 'lib', 'core', 'styles', 'app_text_styles.dart'):
          _appTextStylesDart(),
      _joinPath(repoRoot!, 'lib', 'core', 'styles', 'app_base_theme.dart'):
          appBaseThemeTemplate,
      _joinPath(repoRoot!, 'lib', 'core', 'styles', 'app_breakpoints.dart'):
          _appBreakpointsDart(),
      _joinPath(repoRoot!, 'lib', 'core', 'styles', 'app_paddings.dart'):
          _appPaddingsDart(),
      _joinPath(repoRoot!, 'lib', 'core', 'utils', 'app_key_store.dart'):
          _appKeyStoreDart(),
      _joinPath(
        repoRoot!,
        'lib',
        'core',
        'routing',
        'guards',
        'onboarding_redirect.dart',
      ): _onboardingRedirectDart(),
      _joinPath(repoRoot!, 'lib', 'core', 'utils', 'extensions.dart'):
          _extensionsDart(),
      _joinPath(
        repoRoot!,
        'lib',
        'core',
        'view',
        'domain',
        'repositories',
        'theme_repository.dart',
      ): _themeRepositoryDart(),
      _joinPath(
        repoRoot!,
        'lib',
        'core',
        'view',
        'domain',
        'use_cases',
        'get_theme_mode.dart',
      ): _getThemeModeDart(),
      _joinPath(
        repoRoot!,
        'lib',
        'core',
        'view',
        'domain',
        'use_cases',
        'set_theme_mode.dart',
      ): _setThemeModeDart(),
      _joinPath(
        repoRoot!,
        'lib',
        'core',
        'view',
        'data',
        'repo_impl',
        'theme_repository_shared_prefs_impl.dart',
      ): _themeRepositoryImplDart(),
      _joinPath(
        repoRoot!,
        'lib',
        'core',
        'view',
        'controllers',
        'theme_controller.dart',
      ): _themeControllerDart(),
      _joinPath(
        repoRoot!,
        'lib',
        'core',
        'shared_preferences',
        'domain',
        'repositories',
        'preferences_repository.dart',
      ): _preferencesRepositoryDart(),
      _joinPath(
        repoRoot!,
        'lib',
        'core',
        'shared_preferences',
        'data',
        'repo_impl',
        'preferences_repository_impl.dart',
      ): _preferencesRepositoryImplDart(),
      _joinPath(
        repoRoot!,
        'lib',
        'features',
        'onboarding',
        'domain',
        'repositories',
        'onboarding_repository.dart',
      ): _onboardingRepositoryDart(),
      _joinPath(
        repoRoot!,
        'lib',
        'features',
        'onboarding',
        'domain',
        'use_cases',
        'get_onboarding_state.dart',
      ): _getOnboardingStateDart(),
      _joinPath(
        repoRoot!,
        'lib',
        'features',
        'onboarding',
        'domain',
        'use_cases',
        'set_onboarding_state.dart',
      ): _setOnboardingStateDart(),
      _joinPath(
        repoRoot!,
        'lib',
        'features',
        'onboarding',
        'data',
        'repo_impl',
        'onboarding_repository_shared_prefs_impl.dart',
      ): _onboardingRepositoryImplDart(),
      _joinPath(
        repoRoot!,
        'lib',
        'features',
        'onboarding',
        'view',
        'controllers',
        'onboarding_controller.dart',
      ): _onboardingControllerDart(),
      _joinPath(
        repoRoot!,
        'lib',
        'features',
        'onboarding',
        'view',
        'bindings',
        'onboarding_bindings.dart',
      ): _onboardingBindingsDart(),
      _joinPath(
        repoRoot!,
        'lib',
        'features',
        'onboarding',
        'view',
        'pages',
        'onboarding_page.dart',
      ): _onboardingPageDart(),
      _joinPath(repoRoot!, 'lib', 'l10n', 'app_en.arb'): _appEnArb(),
      _joinPath(repoRoot!, 'lib', 'l10n', 'app_it.arb'): _appItArb(),
      _joinPath(repoRoot!, 'l10n.yaml'): _l10nYaml(),
    };

    for (final entry in scaffoldFiles.entries) {
      await _writeFile(entry.key, entry.value);
    }

    for (final feature in <String>['home', 'profile']) {
      await _writeFeatureScaffold(feature);
    }

    for (final environment in environmentNames) {
      final entrypointPath = _joinPath(
        repoRoot!,
        'lib',
        'entrypoints',
        environment,
        'main.dart',
      );
      await _writeFile(entrypointPath, _entrypointDart(environment));
    }

    await _removeGeneratedFlutterScaffoldArtifacts();

    _log('Architecture scaffold created.');
  }

  Future<void> _ensureFlutterLocalizations(File pubspecFile) async {
    final contents = await pubspecFile.readAsString();
    if (RegExp(
      r'^[ \t]*flutter_localizations:[ \t]*$',
      multiLine: true,
    ).hasMatch(contents)) {
      return;
    }

    final lines = contents.split('\n');
    final updatedLines = <String>[];
    var inserted = false;
    for (final line in lines) {
      updatedLines.add(line);
      if (!inserted && RegExp(r'^[ \t]*dependencies:[ \t]*$').hasMatch(line)) {
        updatedLines.add('  flutter_localizations:');
        updatedLines.add('    sdk: flutter');
        inserted = true;
      }
    }
    await pubspecFile.writeAsString(updatedLines.join('\n'));
  }

  Future<void> _ensureFlutterGenerate(File pubspecFile) async {
    final contents = await pubspecFile.readAsString();
    var inFlutter = false;
    for (final line in contents.split('\n')) {
      if (RegExp(r'^flutter:[ \t]*$').hasMatch(line)) {
        inFlutter = true;
        continue;
      }
      if (RegExp(r'^\S').hasMatch(line)) {
        inFlutter = false;
      }
      if (inFlutter &&
          RegExp(r'^[ \t]+generate:[ \t]*true[ \t]*$').hasMatch(line)) {
        return;
      }
    }

    final lines = contents.split('\n');
    final updatedLines = <String>[];
    var inserted = false;
    for (final line in lines) {
      updatedLines.add(line);
      if (!inserted && RegExp(r'^flutter:[ \t]*$').hasMatch(line)) {
        updatedLines.add('  generate: true');
        inserted = true;
      }
    }
    await pubspecFile.writeAsString(updatedLines.join('\n'));
  }

  Future<void> _writeFeatureScaffold(String feature) async {
    final featureClass = _pascalCase(feature);
    await _writeFile(
      _joinPath(
        repoRoot!,
        'lib',
        'features',
        feature,
        'view',
        'controllers',
        '${feature}_controller.dart',
      ),
      '''
import 'package:get/get.dart';

class ${featureClass}Controller extends GetxController {
  final title = '$featureClass'.obs;
}
''',
    );
    await _writeFile(
      _joinPath(
        repoRoot!,
        'lib',
        'features',
        feature,
        'view',
        'bindings',
        '${feature}_bindings.dart',
      ),
      '''
import 'package:get/get.dart';

import 'package:$flutterProjectName/features/$feature/view/controllers/${feature}_controller.dart';

class ${featureClass}Bindings implements Bindings {
  const ${featureClass}Bindings();

  @override
  void dependencies() {
    if (!Get.isRegistered<${featureClass}Controller>()) {
      Get.lazyPut<${featureClass}Controller>(() => ${featureClass}Controller());
    }
  }
}
''',
    );
    await _writeFile(
      _joinPath(
        repoRoot!,
        'lib',
        'features',
        feature,
        'view',
        'pages',
        '${feature}_page.dart',
      ),
      '''
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:$flutterProjectName/features/$feature/view/controllers/${feature}_controller.dart';

class ${featureClass}Page extends StatelessWidget {
  const ${featureClass}Page({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<${featureClass}Controller>();

    return Scaffold(
      appBar: AppBar(title: Text(controller.title.value)),
      body: Center(
        child: Obx(() => Text(controller.title.value)),
      ),
    );
  }
}
''',
    );
  }

  Future<void> _runIdeConfig() async {
    if (repoRoot == null) {
      _fail('IDE config step failed: repository root is not available.');
    }

    _log('ide_config');
    final vscodeDirectory = Directory(_joinPath(repoRoot!, '.vscode'));
    await vscodeDirectory.create(recursive: true);

    final launchJsonPath = _joinPath(repoRoot!, '.vscode', 'launch.json');
    _log('Writing: $launchJsonPath');
    await _writeFile(launchJsonPath, _launchJson());

    final ideaDirectory = Directory(_joinPath(repoRoot!, '.idea'));
    if (await ideaDirectory.exists()) {
      final runConfigDirectory = Directory(
        _joinPath(repoRoot!, '.idea', 'runConfigurations'),
      );
      await runConfigDirectory.create(recursive: true);
      for (final environment in environmentNames) {
        final configName = _sanitizeSnakeCase('flutter_$environment');
        final path = _joinPath(runConfigDirectory.path, '$configName.xml');
        _log('Writing: $path');
        await _writeFile(path, _jetbrainsRunConfiguration(environment));
      }
    } else {
      _log('JetBrains config skipped: .idea directory not present.');
    }

    _log('IDE run configurations created.');
  }

  Future<void> _runValidation() async {
    if (repoRoot == null) {
      _fail('Validation step failed: repository root is not available.');
    }

    final pubspecPath = _joinPath(repoRoot!, 'pubspec.yaml');
    if (!await File(pubspecPath).exists()) {
      _fail(
        'Validation step failed: pubspec.yaml was not found in the repository root.',
      );
    }

    _log('validation');
    await _removeGeneratedFlutterScaffoldArtifacts();
    await _runCommand(
      'Running: fvm flutter pub get',
      'fvm',
      ['flutter', 'pub', 'get'],
      workingDirectory: repoRoot!,
      failureMessage:
          'Validation step failed while running fvm flutter pub get.',
    );
    await _runCommand(
      'Running: fvm flutter analyze',
      'fvm',
      ['flutter', 'analyze'],
      workingDirectory: repoRoot!,
      failureMessage:
          'Validation step failed while running fvm flutter analyze.',
    );
    _log('Validation completed successfully.');
  }

  Future<void> _removeGeneratedFlutterScaffoldArtifacts() async {
    if (repoRoot == null) {
      return;
    }

    final mainDartPath = _joinPath(repoRoot!, 'lib', 'main.dart');
    final mainDartFile = File(mainDartPath);
    if (await mainDartFile.exists()) {
      _log('Removing generated Flutter template entrypoint: $mainDartPath');
      await mainDartFile.delete();
    }

    final widgetTestPath = _joinPath(repoRoot!, 'test', 'widget_test.dart');
    final widgetTestFile = File(widgetTestPath);
    if (await widgetTestFile.exists()) {
      _log('Removing generated Flutter template widget test: $widgetTestPath');
      await widgetTestFile.delete();
    }

    await for (final entity in Directory(
      repoRoot!,
    ).list(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('widget_test.dart')) {
        continue;
      }

      final contents = await entity.readAsString();
      final looksLikeDefaultFlutterTest =
          contents.contains('package:$flutterProjectName/main.dart') &&
          contents.contains('MyApp');
      if (!looksLikeDefaultFlutterTest) {
        continue;
      }

      _log('Removing generated Flutter template widget test: ${entity.path}');
      await entity.delete();
    }

    final testDirectory = Directory(_joinPath(repoRoot!, 'test'));
    if (await testDirectory.exists()) {
      final isEmpty = await testDirectory.list().isEmpty;
      if (isEmpty) {
        _log(
          'Removing empty generated Flutter test directory: ${testDirectory.path}',
        );
        await testDirectory.delete();
      }
    }
  }

  Future<void> _runCleanup() async {
    final workspace = tempDirectory;
    if (workspace == null) {
      return;
    }

    final directory = Directory(workspace);
    if (!await directory.exists()) {
      tempDirectory = null;
      return;
    }

    _log('cleanup');
    _log('Removing temporary workspace: $workspace');
    try {
      await directory.delete(recursive: true);
    } catch (_) {
      _fail('Cleanup step failed while removing the temporary workspace.');
    }
    tempDirectory = null;
    _log('Temporary workspace removed.');
  }

  Future<void> _deletePathIfExists(String path) async {
    final entityType = await FileSystemEntity.type(path, followLinks: false);
    switch (entityType) {
      case FileSystemEntityType.file:
        await File(path).delete();
        break;
      case FileSystemEntityType.link:
        await Link(path).delete();
        break;
      case FileSystemEntityType.directory:
        await Directory(path).delete(recursive: true);
        break;
      case FileSystemEntityType.notFound:
        break;
      default:
        break;
    }
  }

  Future<void> _writeFile(String path, String contents) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(contents);
  }

  Future<void> _runCommand(
    String? commandLabel,
    String executable,
    List<String> arguments, {
    required String workingDirectory,
    required String failureMessage,
  }) async {
    if (commandLabel != null) {
      _log(commandLabel);
    }

    late final Process process;
    try {
      process = Platform.isWindows
          ? await Process.start(
              executable,
              arguments,
              workingDirectory: workingDirectory,
              runInShell: true,
            )
          : await _startShellCommand(
              _buildShellCommand(executable, arguments),
              workingDirectory: workingDirectory,
            );
    } catch (_) {
      _fail(failureMessage);
    }

    final outputFutures = <Future<void>>[
      _pipeOutput(process.stdout),
      _pipeOutput(process.stderr),
    ];
    final exitCode = await process.exitCode;
    await Future.wait(outputFutures);
    if (exitCode != 0) {
      _fail(failureMessage);
    }
  }

  Future<void> _pipeOutput(Stream<List<int>> stream) async {
    await for (final line
        in stream.transform(utf8.decoder).transform(const LineSplitter())) {
      _log(line);
    }
  }

  String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/').where((part) => part.isNotEmpty);
    return segments.isEmpty ? path : segments.last;
  }

  Future<ProcessResult> _runShellCommandCapture(String command) {
    final shell = _preferredShell();
    return Process.run(shell, ['-lic', command], runInShell: false);
  }

  Future<Process> _startShellCommand(
    String command, {
    required String workingDirectory,
  }) {
    final shell = _preferredShell();
    return Process.start(
      shell,
      ['-lic', command],
      workingDirectory: workingDirectory,
      runInShell: false,
    );
  }

  String _preferredShell() {
    final shell = Platform.environment['SHELL'];
    if (shell != null && shell.trim().isNotEmpty) {
      return shell;
    }
    return '/bin/zsh';
  }

  String _buildShellCommand(String executable, List<String> arguments) {
    return <String>[
      _shellEscape(executable),
      ...arguments.map(_shellEscape),
    ].join(' ');
  }

  String _shellEscape(String value) {
    if (value.isEmpty) {
      return "''";
    }
    return "'${value.replaceAll("'", r"'\''")}'";
  }

  String _appConfigDart() => '''
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
''';

  String _dioDart() =>
      '''
import 'package:dio/dio.dart';
import 'package:$flutterProjectName/core/config/app_config.dart';

Dio provideDio({
  AppConfig? appConfig,
  List<Interceptor>? interceptors,
}) {
  final baseUrl = appConfig?.baseUrl ?? '';
  final options = BaseOptions(
    baseUrl: baseUrl.isEmpty ? 'http://localhost:8080/api' : '\$baseUrl/api',
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
''';

  String _coreBindingsDart() =>
      '''
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:$flutterProjectName/core/config/app_config.dart';
import 'package:$flutterProjectName/core/routing/routes.dart' as root_routes;
import 'package:$flutterProjectName/core/routing/shell_routes.dart' as shell_routes;
import 'package:$flutterProjectName/core/view/controllers/theme_controller.dart';
import 'package:$flutterProjectName/core/view/data/repo_impl/theme_repository_shared_prefs_impl.dart';
import 'package:$flutterProjectName/core/view/domain/repositories/theme_repository.dart';
import 'package:$flutterProjectName/core/view/domain/use_cases/get_theme_mode.dart';
import 'package:$flutterProjectName/core/view/domain/use_cases/set_theme_mode.dart';
import 'package:$flutterProjectName/features/onboarding/data/repo_impl/onboarding_repository_shared_prefs_impl.dart';
import 'package:$flutterProjectName/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:$flutterProjectName/features/onboarding/domain/use_cases/get_onboarding_state.dart';
import 'package:$flutterProjectName/features/onboarding/domain/use_cases/set_onboarding_state.dart';
import 'package:$flutterProjectName/core/network/dio.dart';

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
    Get.put<OnboardingRepository>(
      OnboardingRepositorySharedPrefsImpl(preferences),
      permanent: true,
    );
    Get.put<GetOnboardingStateUseCase>(
      GetOnboardingStateUseCase(Get.find<OnboardingRepository>()),
      permanent: true,
    );
    Get.put<SetOnboardingStateUseCase>(
      SetOnboardingStateUseCase(Get.find<OnboardingRepository>()),
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
''';

  String _appDart() =>
      '''
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:$flutterProjectName/core/bindings/core_bindings.dart';
import 'package:$flutterProjectName/core/config/app_config.dart';
import 'package:$flutterProjectName/core/styles/app_base_theme.dart';
import 'package:$flutterProjectName/core/view/controllers/theme_controller.dart';
import 'package:$flutterProjectName/l10n/app_localizations.dart';

Future<void> bootstrapApp({required AppConfig config}) async {
  final preferences = await SharedPreferences.getInstance();
  CoreBindings(config: config, preferences: preferences).dependencies();

  runApp(const $appClassName());
}

class $appClassName extends StatelessWidget {
  const $appClassName({super.key});

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
''';

  String _appRouteDart() => '''
enum AppRoute {
  onboarding('/onboarding'),
  home('/home'),
  profile('/profile');

  final String path;

  const AppRoute(this.path);
}
''';

  String _goRouterObserverDart() => '''
import 'package:flutter/widgets.dart';

class GoRouterObserver extends NavigatorObserver {}
''';

  String _routesDart() =>
      '''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:$flutterProjectName/core/routing/app_route.dart';
import 'package:$flutterProjectName/core/routing/guards/onboarding_redirect.dart';
import 'package:$flutterProjectName/core/routing/go_router_observer.dart';
import 'package:$flutterProjectName/features/home/view/bindings/home_bindings.dart';
import 'package:$flutterProjectName/features/home/view/pages/home_page.dart';
import 'package:$flutterProjectName/features/onboarding/view/bindings/onboarding_bindings.dart';
import 'package:$flutterProjectName/features/onboarding/view/pages/onboarding_page.dart';
import 'package:$flutterProjectName/features/profile/view/bindings/profile_bindings.dart';
import 'package:$flutterProjectName/features/profile/view/pages/profile_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRootRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoute.onboarding.path,
    observers: [GoRouterObserver()],
    redirect: redirectOnboardingGuard,
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
''';

  String _shellRoutesDart() =>
      '''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:$flutterProjectName/core/routing/app_route.dart';
import 'package:$flutterProjectName/core/routing/guards/onboarding_redirect.dart';
import 'package:$flutterProjectName/core/routing/go_router_observer.dart';
import 'package:$flutterProjectName/core/view/widgets/app_shell.dart';
import 'package:$flutterProjectName/features/home/view/bindings/home_bindings.dart';
import 'package:$flutterProjectName/features/home/view/pages/home_page.dart';
import 'package:$flutterProjectName/features/onboarding/view/bindings/onboarding_bindings.dart';
import 'package:$flutterProjectName/features/onboarding/view/pages/onboarding_page.dart';
import 'package:$flutterProjectName/features/profile/view/bindings/profile_bindings.dart';
import 'package:$flutterProjectName/features/profile/view/pages/profile_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildShellRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoute.onboarding.path,
    observers: [GoRouterObserver()],
    redirect: redirectOnboardingGuard,
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
''';

  String _appShellDart() => '''
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
''';

  String _appTextStylesDart() => '''
import 'package:flutter/material.dart';

abstract class AppTextStyles {
  // ───────────────────── Display ─────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.bold,
    height: 64 / 57,
    letterSpacing: -0.25,
  );
  static const TextStyle displayLargeItalic = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.bold,
    height: 64 / 57,
    letterSpacing: -0.25,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.bold,
    height: 52 / 45,
  );
  static const TextStyle displayMediumItalic = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.bold,
    height: 52 / 45,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 44 / 36,
  );
  static const TextStyle displaySmallItalic = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 44 / 36,
    fontStyle: FontStyle.italic,
  );

  // ───────────────────── Headlines ─────────────────────
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
  );
  static const TextStyle headlineLargeItalic = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 36 / 28,
  );
  static const TextStyle headlineMediumItalic = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 36 / 28,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
  );
  static const TextStyle headlineSmallItalic = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
    fontStyle: FontStyle.italic,
  );

  // ───────────────────── Titles ─────────────────────
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 28 / 22,
  );
  static const TextStyle titleLargeItalic = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 28 / 22,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    letterSpacing: 0.15,
  );
  static const TextStyle titleMediumItalic = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    letterSpacing: 0.15,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    letterSpacing: 0.1,
  );
  static const TextStyle titleSmallItalic = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    letterSpacing: 0.1,
    fontStyle: FontStyle.italic,
  );

  // ───────────────────── Body ─────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    letterSpacing: 0.5,
  );
  static const TextStyle bodyLargeItalic = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    letterSpacing: 0.5,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    letterSpacing: 0.25,
  );
  static const TextStyle bodyMediumItalic = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    letterSpacing: 0.25,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    letterSpacing: 0.4,
  );
  static const TextStyle bodySmallItalic = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    letterSpacing: 0.4,
    fontStyle: FontStyle.italic,
  );

  // ───────────────────── Labels ─────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 20 / 14,
    letterSpacing: 0.1,
  );
  static const TextStyle labelLargeItalic = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 20 / 14,
    letterSpacing: 0.1,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.5,
  );
  static const TextStyle labelMediumItalic = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.5,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 16 / 11,
    letterSpacing: 0.5,
  );
  static const TextStyle labelSmallItalic = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 16 / 11,
    letterSpacing: 0.5,
    fontStyle: FontStyle.italic,
  );

  // ───────────────────── Buttons ─────────────────────
  static const TextStyle buttonPrimary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 20 / 14,
    letterSpacing: 0.75,
    color: Colors.white,
  );
  static const TextStyle buttonPrimaryItalic = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 20 / 14,
    letterSpacing: 0.75,
    color: Colors.white,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle buttonSecondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    letterSpacing: 0.75,
  );
  static const TextStyle buttonSecondaryItalic = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    letterSpacing: 0.75,
    fontStyle: FontStyle.italic,
  );

  // ───────────────────── Captions & Overline ─────────────────────
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 16 / 11,
    letterSpacing: 0.5,
    color: Colors.grey,
  );
}
''';

  String _appBreakpointsDart() => '''
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
''';

  String _appPaddingsDart() => '''
abstract class AppPaddings {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 12.0;
  static const double l = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 36.0;
  static const double venti = 72.0;
  static const double giant = 144.0;
}
''';

  String _appKeyStoreDart() => '''
abstract final class AppKeyStore {
  static const themeMode = 'theme_mode';
  static const onboardingAccepted = 'onboarding_accepted';
}
''';

  String _onboardingRedirectDart() =>
      '''
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:$flutterProjectName/core/routing/app_route.dart';
import 'package:$flutterProjectName/core/utils/app_key_store.dart';

String? redirectOnboardingGuard(BuildContext context, GoRouterState state) {
  final preferences = Get.find<SharedPreferences>();
  final hasAcceptedOnboarding =
      preferences.getBool(AppKeyStore.onboardingAccepted) ?? false;
  final isOnboardingRoute = state.matchedLocation == AppRoute.onboarding.path;

  if (!hasAcceptedOnboarding && !isOnboardingRoute) {
    return AppRoute.onboarding.path;
  }

  if (hasAcceptedOnboarding && isOnboardingRoute) {
    return AppRoute.home.path;
  }

  return null;
}
''';

  String _extensionsDart() => '''
import 'package:flutter/widgets.dart';

extension BuildContextScreenSize on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
}
''';

  String _themeRepositoryDart() => '''
import 'package:flutter/material.dart';

abstract interface class ThemeRepository {
  Future<ThemeMode> getThemeMode();
  Future<void> saveThemeMode(ThemeMode mode);
}
''';

  String _getThemeModeDart() =>
      '''
import 'package:flutter/material.dart';
import 'package:$flutterProjectName/core/view/domain/repositories/theme_repository.dart';

class GetThemeModeUseCase {
  const GetThemeModeUseCase(this._repository);

  final ThemeRepository _repository;

  Future<ThemeMode> call() {
    return _repository.getThemeMode();
  }
}
''';

  String _setThemeModeDart() =>
      '''
import 'package:flutter/material.dart';
import 'package:$flutterProjectName/core/view/domain/repositories/theme_repository.dart';

class SetThemeModeUseCase {
  const SetThemeModeUseCase(this._repository);

  final ThemeRepository _repository;

  Future<void> call(ThemeMode mode) {
    return _repository.saveThemeMode(mode);
  }
}
''';

  String _themeRepositoryImplDart() =>
      '''
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:$flutterProjectName/core/utils/app_key_store.dart';
import 'package:$flutterProjectName/core/view/domain/repositories/theme_repository.dart';

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
''';

  String _themeControllerDart() =>
      '''
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:$flutterProjectName/core/view/domain/use_cases/get_theme_mode.dart';
import 'package:$flutterProjectName/core/view/domain/use_cases/set_theme_mode.dart';

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
''';

  String _preferencesRepositoryDart() => '''
abstract interface class PreferencesRepository {
  String? readString(String key);
  Future<void> writeString(String key, String value);
}
''';

  String _preferencesRepositoryImplDart() =>
      '''
import 'package:shared_preferences/shared_preferences.dart';
import 'package:$flutterProjectName/core/shared_preferences/domain/repositories/preferences_repository.dart';

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
''';

  String _onboardingRepositoryDart() => '''
abstract interface class OnboardingRepository {
  Future<bool> getOnboardingState();
  Future<void> setOnboardingState(bool accepted);
}
''';

  String _getOnboardingStateDart() =>
      '''
import 'package:$flutterProjectName/features/onboarding/domain/repositories/onboarding_repository.dart';

class GetOnboardingStateUseCase {
  const GetOnboardingStateUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<bool> call() {
    return _repository.getOnboardingState();
  }
}
''';

  String _setOnboardingStateDart() =>
      '''
import 'package:$flutterProjectName/features/onboarding/domain/repositories/onboarding_repository.dart';

class SetOnboardingStateUseCase {
  const SetOnboardingStateUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<void> call(bool accepted) {
    return _repository.setOnboardingState(accepted);
  }
}
''';

  String _onboardingRepositoryImplDart() =>
      '''
import 'package:shared_preferences/shared_preferences.dart';
import 'package:$flutterProjectName/core/utils/app_key_store.dart';
import 'package:$flutterProjectName/features/onboarding/domain/repositories/onboarding_repository.dart';

class OnboardingRepositorySharedPrefsImpl implements OnboardingRepository {
  const OnboardingRepositorySharedPrefsImpl(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<bool> getOnboardingState() async {
    return _preferences.getBool(AppKeyStore.onboardingAccepted) ?? false;
  }

  @override
  Future<void> setOnboardingState(bool accepted) async {
    await _preferences.setBool(AppKeyStore.onboardingAccepted, accepted);
  }
}
''';

  String _onboardingControllerDart() =>
      '''
import 'package:get/get.dart';
import 'package:$flutterProjectName/features/onboarding/domain/use_cases/get_onboarding_state.dart';
import 'package:$flutterProjectName/features/onboarding/domain/use_cases/set_onboarding_state.dart';

class OnboardingController extends GetxController {
  OnboardingController({
    required GetOnboardingStateUseCase getOnboardingState,
    required SetOnboardingStateUseCase setOnboardingState,
  }) : _getOnboardingState = getOnboardingState,
       _setOnboardingState = setOnboardingState;

  final GetOnboardingStateUseCase _getOnboardingState;
  final SetOnboardingStateUseCase _setOnboardingState;

  final title = 'Onboarding'.obs;
  final isAccepted = false.obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadOnboardingState();
  }

  Future<void> _loadOnboardingState() async {
    isAccepted.value = await _getOnboardingState();
    isLoading.value = false;
  }

  Future<void> setAccepted(bool value) async {
    isAccepted.value = value;
    await _setOnboardingState(value);
  }
}
''';

  String _onboardingBindingsDart() =>
      '''
import 'package:get/get.dart';
import 'package:$flutterProjectName/features/onboarding/domain/use_cases/get_onboarding_state.dart';
import 'package:$flutterProjectName/features/onboarding/domain/use_cases/set_onboarding_state.dart';
import 'package:$flutterProjectName/features/onboarding/view/controllers/onboarding_controller.dart';

class OnboardingBindings implements Bindings {
  const OnboardingBindings();

  @override
  void dependencies() {
    if (!Get.isRegistered<OnboardingController>()) {
      Get.lazyPut<OnboardingController>(
        () => OnboardingController(
          getOnboardingState: Get.find<GetOnboardingStateUseCase>(),
          setOnboardingState: Get.find<SetOnboardingStateUseCase>(),
        ),
      );
    }
  }
}
''';

  String _onboardingPageDart() =>
      '''
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:$flutterProjectName/core/routing/app_route.dart';
import 'package:$flutterProjectName/features/onboarding/view/controllers/onboarding_controller.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();

    return Scaffold(
      appBar: AppBar(title: Text(controller.title.value)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prima di continuare devi accettare l\\'onboarding.',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Conferma di aver letto e accettato per sbloccare il pulsante di accesso alla home.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Spacer(),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Accetto e voglio proseguire'),
                  value: controller.isAccepted.value,
                  onChanged: (value) => controller.setAccepted(value ?? false),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isAccepted.value
                        ? () => context.go(AppRoute.home.path)
                        : null,
                    child: const Text('Continua'),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
''';

  String _appEnArb() => '''
{
  "@@locale": "en",
  "appTitle": "App"
}
''';

  String _appItArb() => '''
{
  "@@locale": "it",
  "appTitle": "App"
}
''';

  String _l10nYaml() => '''
arb-dir: lib/l10n
template-arb-file: app_it.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
nullable-getter: false
''';

  String _entrypointDart(String environment) =>
      '''
import 'package:flutter/material.dart';
import 'package:$flutterProjectName/app.dart';
import 'package:$flutterProjectName/core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config = AppConfig(
    environment: '$environment',
    displayName: '$appDisplayName',
    baseUrl: 'http://localhost:8080',
    routerShape: '$routerShape',
  );
  await bootstrapApp(config: config);
}
''';

  String _launchJson() {
    final buffer = StringBuffer()
      ..writeln('{')
      ..writeln('  "version": "0.2.0",')
      ..writeln('  "configurations": [');
    for (var index = 0; index < environmentNames.length; index++) {
      final environment = environmentNames[index];
      buffer.writeln('    {');
      buffer.writeln('      "name": "Flutter $environment",');
      buffer.writeln('      "request": "launch",');
      buffer.writeln('      "type": "dart",');
      buffer.write(
        '      "program": "lib/entrypoints/$environment/main.dart"\n',
      );
      buffer.writeln(index < environmentNames.length - 1 ? '    },' : '    }');
    }
    buffer
      ..writeln('  ]')
      ..writeln('}');
    return buffer.toString();
  }

  String _jetbrainsRunConfiguration(String environment) =>
      '''
<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="Flutter $environment" type="FlutterRunConfigurationType" factoryName="Flutter">
    <option name="filePath" value="\$PROJECT_DIR\$/lib/entrypoints/$environment/main.dart" />
    <method v="2" />
  </configuration>
</component>
''';
}
