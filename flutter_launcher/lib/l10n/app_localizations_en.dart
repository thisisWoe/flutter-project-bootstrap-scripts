// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'App';

  @override
  String get onboardingTitle => 'Flutter Launcher';

  @override
  String get onboardingHeading => 'Requirements to create a Flutter project';

  @override
  String get onboardingDescription =>
      'This launcher will run the commands needed to create a Flutter project from scratch. Before continuing, make sure these requirements are satisfied.';

  @override
  String get onboardingPrerequisitesTitle => 'Prerequisites';

  @override
  String get onboardingRequirementFvm =>
      'FVM is working and available in PATH.';

  @override
  String get onboardingRequirementInternet => 'Internet access is available.';

  @override
  String get onboardingRequirementShell =>
      'bash on Unix/macOS, or cmd and PowerShell on Windows.';

  @override
  String get onboardingRequirementTargetDirectory =>
      'A target directory already exists and is not already occupied by a Flutter project.';

  @override
  String get onboardingToolchainsTitle => 'Platform toolchains';

  @override
  String get onboardingToolchainsDescription =>
      'If you select certain platforms, you also need the related Flutter toolchains.';

  @override
  String get onboardingPlatformAndroid => 'android';

  @override
  String get onboardingPlatformRequirementAndroid =>
      'Android SDK + Android toolchain.';

  @override
  String get onboardingPlatformIos => 'ios';

  @override
  String get onboardingPlatformRequirementIos =>
      'macOS + Xcode + iOS toolchain.';

  @override
  String get onboardingPlatformMacos => 'macos';

  @override
  String get onboardingPlatformRequirementMacos => 'macOS + Xcode.';

  @override
  String get onboardingPlatformWeb => 'web';

  @override
  String get onboardingPlatformRequirementWeb =>
      'A Flutter-supported web toolchain.';

  @override
  String get onboardingPlatformWindows => 'windows';

  @override
  String get onboardingPlatformRequirementWindows =>
      'Windows desktop toolchain.';

  @override
  String get onboardingPlatformLinux => 'linux';

  @override
  String get onboardingPlatformRequirementLinux => 'Linux desktop toolchain.';

  @override
  String get onboardingAcceptanceLabel =>
      'I confirm that I checked the prerequisites and want to continue';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get homeTitle => 'Project bootstrap';

  @override
  String get homeStepProjectTitle => 'Project';

  @override
  String get homeStepProjectSubtitle => 'Path and app names';

  @override
  String get homeTargetRootLabel => 'Destination folder';

  @override
  String get homeTargetRootHelper =>
      'Leave empty to use the current directory, or select an existing and safe target folder.';

  @override
  String get homeTargetRootRequiredError => 'Target root is required.';

  @override
  String get homeTargetRootNotFoundError =>
      'The target directory does not exist.';

  @override
  String get homeTargetRootNotDirectoryError =>
      'Target root must be a directory, not a file.';

  @override
  String get homeTargetRootNotResolvableError =>
      'Target root cannot be resolved to a valid absolute path.';

  @override
  String get homeTargetRootNotAccessibleError =>
      'The target directory must be readable, writable, and traversable.';

  @override
  String get homeTargetRootUnsafeFilesystemRootError =>
      'The filesystem root is not a valid target.';

  @override
  String get homeTargetRootUnsafeUserHomeError =>
      'The user home directory is not a valid target.';

  @override
  String get homeTargetRootUnsafeHighLevelDirectoryError =>
      'Choose a more specific directory lower in the hierarchy.';

  @override
  String get homeTargetRootSameAsBootstrapRepositoryError =>
      'The bootstrap repository directory cannot be used as target root.';

  @override
  String get homeTargetRootExistingFlutterProjectError =>
      'The directory already contains a Flutter project.';

  @override
  String get homeTargetRootPartialFlutterProjectError =>
      'The directory contains partial Flutter project traces.';

  @override
  String get homeTargetRootUnsupportedContentsError =>
      'The directory must be empty or contain only tolerated files such as README.md, .gitignore, LICENSE, or the .git folder.';

  @override
  String get homeTargetRootInternalTemporaryDirectoryError =>
      'The target directory cannot be an internal bootstrap temporary directory.';

  @override
  String get homeChooseFolderTooltip => 'Choose folder';

  @override
  String get homeProjectNameLabel => 'Project name';

  @override
  String get homeProjectNameHelper =>
      'Used to generate the technical project names, such as the Flutter package and platform identifiers.';

  @override
  String get homeProjectNameRequiredError => 'Project name is required.';

  @override
  String get homeProjectNameTooLongError =>
      'Project name is too long. Use at most 80 characters.';

  @override
  String get homeProjectNameInvalidCharactersError =>
      'Project name may contain only letters, hyphen (-), and underscore (_).';

  @override
  String get homeProjectNameInvalidDerivedFlutterNameError =>
      'Project name does not generate a valid Flutter/Dart package name.';

  @override
  String get homeProjectNameDerivedStartsWithDigitError =>
      'Project name generates a technical identifier that starts with a digit.';

  @override
  String get homeProjectNameInvalidDerivedPlatformIdentifierError =>
      'Project name does not generate valid Android/iOS identifiers.';

  @override
  String get homeProjectNameDerivedTooWeakError =>
      'Project name generates identifiers that are too weak or meaningless.';

  @override
  String get homeProjectNameDerivedTooLongError =>
      'Project name generates technical identifiers that are too long.';

  @override
  String get homeAppDisplayNameLabel => 'App display name';

  @override
  String get homeAppDisplayNameHint => 'My App';

  @override
  String get homeAppDisplayNameHelper =>
      'Used as the user-facing app name inside the generated code and final app.';

  @override
  String get homeAppDisplayNameRequiredError => 'App display name is required.';

  @override
  String get homeAppDisplayNameTooLongError =>
      'App display name is too long. Use at most 60 characters.';

  @override
  String get homeAppDisplayNameLeadingOrTrailingWhitespaceError =>
      'App display name must not have leading or trailing spaces.';

  @override
  String get homeAppDisplayNameContainsNewlineError =>
      'App display name cannot contain newlines.';

  @override
  String get homeAppDisplayNameContainsControlCharacterError =>
      'App display name contains unsupported control characters.';

  @override
  String get homeAppDisplayNameContainsSingleQuoteError =>
      'App display name cannot contain single quotes.';

  @override
  String get homeAppDisplayNameContainsBackslashError =>
      'App display name cannot contain backslashes.';

  @override
  String get homeAppDisplayNameNoVisibleCharacterError =>
      'App display name must contain at least one visible character.';

  @override
  String get homeOrganizationIdLabel => 'Organization ID';

  @override
  String get homeOrganizationIdHint => 'com.example';

  @override
  String get homeOrganizationIdHelper =>
      'Required reverse-domain identifier used as the base for Android and Apple package identifiers.';

  @override
  String get homeOrganizationIdRequiredError => 'Organization ID is required.';

  @override
  String get homeOrganizationIdTooLongError =>
      'Organization ID is too long. Use at most 120 characters.';

  @override
  String get homeOrganizationIdLeadingOrTrailingWhitespaceError =>
      'Organization ID must not have leading or trailing spaces.';

  @override
  String get homeOrganizationIdInvalidFormatError =>
      'Organization ID must use reverse-domain format, for example com.example or it.company.app.';

  @override
  String get homeStepPlatformsTitle => 'Platforms';

  @override
  String get homeStepPlatformsSubtitle => 'Select target platforms';

  @override
  String get homePlatformsRequiredError =>
      'Select at least one target platform.';

  @override
  String get homeStepEnvironmentsTitle => 'Environments';

  @override
  String get homeStepEnvironmentsSubtitle => 'Pick at least two';

  @override
  String get homeCustomEnvironmentLabel => 'Custom environment';

  @override
  String get homeCustomEnvironmentHint => 'staging';

  @override
  String get homeAddEnvironment => 'Add';

  @override
  String get homeEnvironmentsRequiredError =>
      'Select at least two environments.';

  @override
  String get homeStepRouterTitle => 'Router';

  @override
  String get homeStepRouterSubtitle => 'Choose the router shape';

  @override
  String get homeRouterShapeRequiredError => 'Select a router shape.';

  @override
  String get homeCollectedValuesTitle => 'Collected values';

  @override
  String get homeContinue => 'Continue';

  @override
  String get homeFinish => 'Finish';

  @override
  String get homeBack => 'Back';
}
