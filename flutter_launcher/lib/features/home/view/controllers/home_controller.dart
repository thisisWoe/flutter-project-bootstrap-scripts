import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter_launcher/features/home/domain/services/bootstrap_service.dart';

enum TargetRootValidationError {
  notFound,
  notDirectory,
  notResolvable,
  notAccessible,
  unsafeFilesystemRoot,
  unsafeUserHome,
  unsafeHighLevelDirectory,
  sameAsBootstrapRepository,
  existingFlutterProject,
  partialFlutterProject,
  unsupportedContents,
  internalTemporaryDirectory,
}

enum ProjectNameValidationError {
  required,
  tooLong,
  invalidCharacters,
  invalidDerivedFlutterName,
  derivedStartsWithDigit,
  invalidDerivedPlatformIdentifier,
  derivedTooWeak,
  derivedTooLong,
}

enum AppDisplayNameValidationError {
  required,
  tooLong,
  leadingOrTrailingWhitespace,
  containsNewline,
  containsControlCharacter,
  containsSingleQuote,
  containsBackslash,
  noVisibleCharacter,
}

enum OrganizationIdValidationError {
  required,
  tooLong,
  leadingOrTrailingWhitespace,
  invalidFormat,
}

class HomeController extends GetxController {
  HomeController({BootstrapService? bootstrapService})
    : _bootstrapService = bootstrapService ?? const BootstrapService();

  static const _maxProjectNameLength = 80;
  static const _maxDerivedFlutterNameLength = 50;
  static const _maxDerivedPlatformNameLength = 40;
  static const _maxAppDisplayNameLength = 60;
  static const _maxOrganizationIdLength = 120;

  static const _allowedTargetRootEntries = <String>{
    '.git',
    '.gitattributes',
    '.gitignore',
    'LICENSE',
    'LICENSE.md',
    'README',
    'README.md',
  };

  static const _flutterProjectMarkers = <String>{
    '.dart_tool',
    'analysis_options.yaml',
    'android',
    'ios',
    'lib',
    'linux',
    'macos',
    'pubspec.yaml',
    'test',
    'web',
    'windows',
  };

  static const supportedPlatforms = <String>[
    'android',
    'ios',
    'web',
    'macos',
    'windows',
    'linux',
  ];

  static const defaultEnvironments = <String>['dev', 'test', 'prod'];

  static const routerShapes = <String>['root', 'shell'];

  final currentStep = 0.obs;

  final targetRootController = TextEditingController();
  final projectNameController = TextEditingController();
  final appDisplayNameController = TextEditingController();
  final organizationIdController = TextEditingController();
  final customEnvironmentController = TextEditingController();

  final selectedPlatforms = <String>[].obs;
  final selectedEnvironments = <String>[].obs;
  final routerShape = RxnString();

  final platformsHasError = false.obs;
  final environmentsHasError = false.obs;
  final routerShapeHasError = false.obs;

  final targetRootError = Rxn<TargetRootValidationError>();
  final projectNameError = Rxn<ProjectNameValidationError>();
  final appDisplayNameError = Rxn<AppDisplayNameValidationError>();
  final organizationIdError = Rxn<OrganizationIdValidationError>();
  final isRunningBootstrap = false.obs;
  final bootstrapLogs = <String>[].obs;
  final bootstrapError = RxnString();
  final bootstrapSuccess = RxnString();

  final BootstrapService _bootstrapService;

  String get targetRoot {
    final trimmed = targetRootController.text.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }

    return Directory.current.path;
  }

  String get projectName => projectNameController.text.trim();

  String get appDisplayName => appDisplayNameController.text.trim();

  String get organizationId => organizationIdController.text.trim();

  Map<String, Object?> get collectedValues => <String, Object?>{
    'target_root': targetRoot,
    'project_name': projectName,
    'app_display_name': appDisplayName,
    'organization_id': organizationId,
    'target_platforms': selectedPlatforms.toList(growable: false),
    'environment_names': selectedEnvironments.toList(growable: false),
    'router_shape': routerShape.value,
  };

  Future<void> pickTargetRoot() async {
    try {
      final selectedDirectory = await getDirectoryPath();

      if (selectedDirectory == null || selectedDirectory.trim().isEmpty) {
        return;
      }

      targetRootController.text = selectedDirectory;
      targetRootError.value = null;
    } catch (e) {
      debugPrint('Error picking directory: $e');
      Get.snackbar(
        'Folder picker unavailable',
        'Restart the desktop app after adding native plugins.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  bool isStepValid(int stepIndex) {
    return switch (stepIndex) {
      0 => _validateProjectStep(),
      1 => _validatePlatformsStep(),
      2 => _validateEnvironmentsStep(),
      3 => _validateRouterShapeStep(),
      _ => false,
    };
  }

  void goToStep(int stepIndex) {
    if (stepIndex < 0 || stepIndex > 3) {
      return;
    }

    if (stepIndex > currentStep.value && !isStepValid(currentStep.value)) {
      return;
    }

    currentStep.value = stepIndex;
  }

  void continueStep() {
    if (!isStepValid(currentStep.value)) {
      return;
    }

    if (currentStep.value < 3) {
      currentStep.value++;
    }
  }

  Future<void> submit() async {
    if (!isStepValid(3) || isRunningBootstrap.value) {
      return;
    }

    isRunningBootstrap.value = true;
    bootstrapLogs.clear();
    bootstrapError.value = null;
    bootstrapSuccess.value = null;

    try {
      await _bootstrapService.run(
        BootstrapRequest(
          targetRoot: targetRoot,
          projectName: projectName,
          appDisplayName: appDisplayName,
          organizationId: organizationId,
          targetPlatforms: selectedPlatforms.toList(growable: false),
          environmentNames: selectedEnvironments.toList(growable: false),
          routerShape: routerShape.value ?? '',
        ),
        onLog: _appendBootstrapLog,
      );
      bootstrapSuccess.value = 'Bootstrap completed successfully.';
      Get.snackbar(
        'Bootstrap completed',
        'Project scaffold created successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on BootstrapFailure catch (error) {
      bootstrapError.value = error.message;
      Get.snackbar(
        'Bootstrap failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      final message = 'Unexpected error: $error';
      bootstrapError.value = message;
      Get.snackbar(
        'Bootstrap failed',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isRunningBootstrap.value = false;
    }
  }

  void _appendBootstrapLog(String message) {
    bootstrapLogs.add(message);
  }

  void cancelStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  void togglePlatform(String platform, bool isSelected) {
    if (isSelected) {
      if (!selectedPlatforms.contains(platform)) {
        selectedPlatforms.add(platform);
      }
    } else {
      selectedPlatforms.remove(platform);
    }

    platformsHasError.value = false;
  }

  void toggleEnvironment(String environment, bool isSelected) {
    if (isSelected) {
      if (!selectedEnvironments.contains(environment)) {
        selectedEnvironments.add(environment);
      }
    } else {
      selectedEnvironments.remove(environment);
    }

    environmentsHasError.value = false;
  }

  void addCustomEnvironment() {
    final candidate = customEnvironmentController.text.trim().toLowerCase();

    if (candidate.isEmpty) {
      return;
    }

    if (!selectedEnvironments.contains(candidate)) {
      selectedEnvironments.add(candidate);
    }

    customEnvironmentController.clear();
    environmentsHasError.value = false;
  }

  void removeEnvironment(String environment) {
    selectedEnvironments.remove(environment);
  }

  void setRouterShape(String? value) {
    routerShape.value = value;
    routerShapeHasError.value = false;
  }

  bool _validateProjectStep() {
    targetRootError.value = _validateTargetRoot();
    projectNameError.value = _validateProjectName();
    appDisplayNameError.value = _validateAppDisplayName();
    organizationIdError.value = _validateOrganizationId();

    return targetRootError.value == null &&
        projectNameError.value == null &&
        appDisplayNameError.value == null &&
        organizationIdError.value == null;
  }

  bool _validatePlatformsStep() {
    final isValid = selectedPlatforms.isNotEmpty;
    platformsHasError.value = !isValid;
    return isValid;
  }

  bool _validateEnvironmentsStep() {
    final isValid = selectedEnvironments.length >= 2;
    environmentsHasError.value = !isValid;
    return isValid;
  }

  bool _validateRouterShapeStep() {
    final isValid = routerShapes.contains(routerShape.value);
    routerShapeHasError.value = !isValid;
    return isValid;
  }

  @override
  void onClose() {
    targetRootController.dispose();
    projectNameController.dispose();
    appDisplayNameController.dispose();
    organizationIdController.dispose();
    customEnvironmentController.dispose();
    super.onClose();
  }

  TargetRootValidationError? _validateTargetRoot() {
    final candidatePath = targetRoot;
    final candidateDirectory = Directory(candidatePath);

    String canonicalPath;
    try {
      canonicalPath = candidateDirectory.resolveSymbolicLinksSync();
    } catch (_) {
      return TargetRootValidationError.notResolvable;
    }

    final entityType = FileSystemEntity.typeSync(
      canonicalPath,
      followLinks: true,
    );
    if (entityType == FileSystemEntityType.notFound) {
      return TargetRootValidationError.notFound;
    }
    if (entityType != FileSystemEntityType.directory) {
      return TargetRootValidationError.notDirectory;
    }

    final targetDirectory = Directory(canonicalPath);
    if (!_isDirectoryAccessible(targetDirectory)) {
      return TargetRootValidationError.notAccessible;
    }

    if (_isFilesystemRoot(canonicalPath)) {
      return TargetRootValidationError.unsafeFilesystemRoot;
    }

    final userHomePath = _resolveUserHomePath();
    if (userHomePath != null && _pathsEqual(canonicalPath, userHomePath)) {
      return TargetRootValidationError.unsafeUserHome;
    }

    if (_isHighLevelDirectory(canonicalPath)) {
      return TargetRootValidationError.unsafeHighLevelDirectory;
    }

    final bootstrapRepositoryPath = _resolveBootstrapRepositoryPath();
    if (_pathsEqual(canonicalPath, bootstrapRepositoryPath)) {
      return TargetRootValidationError.sameAsBootstrapRepository;
    }

    if (_looksLikeInternalBootstrapTempDirectory(canonicalPath)) {
      return TargetRootValidationError.internalTemporaryDirectory;
    }

    final entryNames = _safeListEntryNames(targetDirectory);
    final markerCount = entryNames
        .where(_flutterProjectMarkers.contains)
        .length;

    if (_looksLikeFlutterProject(entryNames)) {
      return TargetRootValidationError.existingFlutterProject;
    }

    if (markerCount > 0) {
      return TargetRootValidationError.partialFlutterProject;
    }

    final hasUnsupportedEntries = entryNames.any(
      (entryName) => !_allowedTargetRootEntries.contains(entryName),
    );
    if (hasUnsupportedEntries) {
      return TargetRootValidationError.unsupportedContents;
    }

    return null;
  }

  ProjectNameValidationError? _validateProjectName() {
    final value = projectName;
    if (value.isEmpty) {
      return ProjectNameValidationError.required;
    }
    if (value.length > _maxProjectNameLength) {
      return ProjectNameValidationError.tooLong;
    }

    if (!RegExp(r'^[A-Za-z_-]+$').hasMatch(value)) {
      return ProjectNameValidationError.invalidCharacters;
    }

    final flutterName = _deriveFlutterPackageName(value);
    if (flutterName.isEmpty || !RegExp(r'^[a-z0-9_]+$').hasMatch(flutterName)) {
      return ProjectNameValidationError.invalidDerivedFlutterName;
    }
    if (RegExp(r'^[0-9]').hasMatch(flutterName)) {
      return ProjectNameValidationError.derivedStartsWithDigit;
    }
    if (flutterName.length > _maxDerivedFlutterNameLength) {
      return ProjectNameValidationError.derivedTooLong;
    }

    final compactFlutterName = flutterName.replaceAll('_', '');
    if (compactFlutterName.length < 3 ||
        !RegExp(r'[a-z]').hasMatch(compactFlutterName)) {
      return ProjectNameValidationError.derivedTooWeak;
    }

    final platformIdentifier = _derivePlatformIdentifier(value);
    if (platformIdentifier.isEmpty ||
        !RegExp(r'^[a-z0-9]+$').hasMatch(platformIdentifier)) {
      return ProjectNameValidationError.invalidDerivedPlatformIdentifier;
    }
    if (platformIdentifier.length > _maxDerivedPlatformNameLength) {
      return ProjectNameValidationError.derivedTooLong;
    }
    if (platformIdentifier.length < 3 ||
        !RegExp(r'[a-z]').hasMatch(platformIdentifier)) {
      return ProjectNameValidationError.derivedTooWeak;
    }

    return null;
  }

  AppDisplayNameValidationError? _validateAppDisplayName() {
    final rawValue = appDisplayNameController.text;
    if (rawValue.isEmpty) {
      return AppDisplayNameValidationError.required;
    }

    final trimmedValue = rawValue.trim();
    if (trimmedValue.isEmpty) {
      return AppDisplayNameValidationError.noVisibleCharacter;
    }
    if (rawValue != trimmedValue) {
      return AppDisplayNameValidationError.leadingOrTrailingWhitespace;
    }
    if (trimmedValue.length > _maxAppDisplayNameLength) {
      return AppDisplayNameValidationError.tooLong;
    }
    if (trimmedValue.contains('\n') || trimmedValue.contains('\r')) {
      return AppDisplayNameValidationError.containsNewline;
    }
    if (RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]').hasMatch(trimmedValue)) {
      return AppDisplayNameValidationError.containsControlCharacter;
    }
    if (trimmedValue.contains('\'')) {
      return AppDisplayNameValidationError.containsSingleQuote;
    }
    if (trimmedValue.contains(r'\')) {
      return AppDisplayNameValidationError.containsBackslash;
    }

    return null;
  }

  OrganizationIdValidationError? _validateOrganizationId() {
    final rawValue = organizationIdController.text;
    if (rawValue.isEmpty) {
      return OrganizationIdValidationError.required;
    }

    final trimmedValue = rawValue.trim();
    if (trimmedValue.isEmpty) {
      return OrganizationIdValidationError.required;
    }
    if (rawValue != trimmedValue) {
      return OrganizationIdValidationError.leadingOrTrailingWhitespace;
    }
    if (trimmedValue.length > _maxOrganizationIdLength) {
      return OrganizationIdValidationError.tooLong;
    }
    if (!RegExp(
      r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$',
    ).hasMatch(trimmedValue)) {
      return OrganizationIdValidationError.invalidFormat;
    }

    return null;
  }

  bool _isDirectoryAccessible(Directory directory) {
    try {
      directory.listSync(followLinks: false);
    } catch (_) {
      return false;
    }

    Directory? probeDirectory;
    try {
      probeDirectory = directory.createTempSync('.flutter_launcher_probe_');
    } catch (_) {
      return false;
    } finally {
      try {
        probeDirectory?.deleteSync(recursive: true);
      } catch (_) {}
    }

    return true;
  }

  bool _isFilesystemRoot(String path) {
    final directory = Directory(path);
    return _pathsEqual(directory.parent.path, path);
  }

  bool _isHighLevelDirectory(String path) {
    final normalized = path.replaceAll('\\', '/');
    final rootless = normalized.replaceFirst(RegExp(r'^[A-Za-z]:/?'), '');
    final segments = rootless.split('/').where((segment) => segment.isNotEmpty);
    return segments.length <= 2;
  }

  bool _pathsEqual(String left, String right) {
    return left.replaceAll('\\', '/') == right.replaceAll('\\', '/');
  }

  String? _resolveUserHomePath() {
    final homeCandidate =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        _buildWindowsHomeFromParts();
    if (homeCandidate == null || homeCandidate.trim().isEmpty) {
      return null;
    }

    try {
      return Directory(homeCandidate).resolveSymbolicLinksSync();
    } catch (_) {
      return Directory(homeCandidate).absolute.path;
    }
  }

  String? _buildWindowsHomeFromParts() {
    final homeDrive = Platform.environment['HOMEDRIVE'];
    final homePath = Platform.environment['HOMEPATH'];
    if (homeDrive == null || homePath == null) {
      return null;
    }

    return '$homeDrive$homePath';
  }

  String _resolveBootstrapRepositoryPath() {
    try {
      return Directory.current.resolveSymbolicLinksSync();
    } catch (_) {
      return Directory.current.absolute.path;
    }
  }

  bool _looksLikeInternalBootstrapTempDirectory(String path) {
    final normalized = path.replaceAll('\\', '/').toLowerCase();
    final lastSegment = normalized
        .split('/')
        .where((part) => part.isNotEmpty)
        .lastOrNull;

    return normalized.contains('flutter-bootstrap') ||
        (lastSegment != null && lastSegment.startsWith('flutter-bootstrap.'));
  }

  Set<String> _safeListEntryNames(Directory directory) {
    try {
      return directory
          .listSync(followLinks: false)
          .map((entity) => _entityName(entity.path))
          .where((entry) => entry.isNotEmpty)
          .toSet();
    } catch (_) {
      return const <String>{};
    }
  }

  String _entityName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/').where((part) => part.isNotEmpty);
    return segments.isEmpty ? path : segments.last;
  }

  bool _looksLikeFlutterProject(Set<String> entryNames) {
    return entryNames.contains('pubspec.yaml') &&
        entryNames.contains('lib') &&
        (entryNames.contains('android') ||
            entryNames.contains('ios') ||
            entryNames.contains('web') ||
            entryNames.contains('macos') ||
            entryNames.contains('linux') ||
            entryNames.contains('windows'));
  }

  String _deriveFlutterPackageName(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  String _derivePlatformIdentifier(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }
}
