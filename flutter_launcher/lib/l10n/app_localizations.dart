import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In it, this message translates to:
  /// **'App'**
  String get appTitle;

  /// No description provided for @onboardingTitle.
  ///
  /// In it, this message translates to:
  /// **'Flutter Launcher'**
  String get onboardingTitle;

  /// No description provided for @onboardingHeading.
  ///
  /// In it, this message translates to:
  /// **'Prerequisiti per creare un progetto Flutter'**
  String get onboardingHeading;

  /// No description provided for @onboardingDescription.
  ///
  /// In it, this message translates to:
  /// **'Questo launcher eseguirà i comandi necessari per creare un progetto Flutter da zero. Prima di continuare, verifica che questi prerequisiti siano soddisfatti.'**
  String get onboardingDescription;

  /// No description provided for @onboardingPrerequisitesTitle.
  ///
  /// In it, this message translates to:
  /// **'Prerequisiti'**
  String get onboardingPrerequisitesTitle;

  /// No description provided for @onboardingRequirementFvm.
  ///
  /// In it, this message translates to:
  /// **'FVM funzionante e disponibile nel PATH.'**
  String get onboardingRequirementFvm;

  /// No description provided for @onboardingRequirementInternet.
  ///
  /// In it, this message translates to:
  /// **'Accesso a internet.'**
  String get onboardingRequirementInternet;

  /// No description provided for @onboardingRequirementShell.
  ///
  /// In it, this message translates to:
  /// **'bash su Unix/macOS oppure cmd e PowerShell su Windows.'**
  String get onboardingRequirementShell;

  /// No description provided for @onboardingRequirementTargetDirectory.
  ///
  /// In it, this message translates to:
  /// **'Esiste una directory target e non è già occupata da un progetto Flutter.'**
  String get onboardingRequirementTargetDirectory;

  /// No description provided for @onboardingToolchainsTitle.
  ///
  /// In it, this message translates to:
  /// **'Toolchain per piattaforma'**
  String get onboardingToolchainsTitle;

  /// No description provided for @onboardingToolchainsDescription.
  ///
  /// In it, this message translates to:
  /// **'Se selezioni certe piattaforme, servono anche le relative toolchain Flutter.'**
  String get onboardingToolchainsDescription;

  /// No description provided for @onboardingPlatformAndroid.
  ///
  /// In it, this message translates to:
  /// **'android'**
  String get onboardingPlatformAndroid;

  /// No description provided for @onboardingPlatformRequirementAndroid.
  ///
  /// In it, this message translates to:
  /// **'Android SDK + toolchain Android.'**
  String get onboardingPlatformRequirementAndroid;

  /// No description provided for @onboardingPlatformIos.
  ///
  /// In it, this message translates to:
  /// **'ios'**
  String get onboardingPlatformIos;

  /// No description provided for @onboardingPlatformRequirementIos.
  ///
  /// In it, this message translates to:
  /// **'macOS + Xcode + toolchain iOS.'**
  String get onboardingPlatformRequirementIos;

  /// No description provided for @onboardingPlatformMacos.
  ///
  /// In it, this message translates to:
  /// **'macos'**
  String get onboardingPlatformMacos;

  /// No description provided for @onboardingPlatformRequirementMacos.
  ///
  /// In it, this message translates to:
  /// **'macOS + Xcode.'**
  String get onboardingPlatformRequirementMacos;

  /// No description provided for @onboardingPlatformWeb.
  ///
  /// In it, this message translates to:
  /// **'web'**
  String get onboardingPlatformWeb;

  /// No description provided for @onboardingPlatformRequirementWeb.
  ///
  /// In it, this message translates to:
  /// **'Toolchain web supportata da Flutter.'**
  String get onboardingPlatformRequirementWeb;

  /// No description provided for @onboardingPlatformWindows.
  ///
  /// In it, this message translates to:
  /// **'windows'**
  String get onboardingPlatformWindows;

  /// No description provided for @onboardingPlatformRequirementWindows.
  ///
  /// In it, this message translates to:
  /// **'Toolchain desktop Windows.'**
  String get onboardingPlatformRequirementWindows;

  /// No description provided for @onboardingPlatformLinux.
  ///
  /// In it, this message translates to:
  /// **'linux'**
  String get onboardingPlatformLinux;

  /// No description provided for @onboardingPlatformRequirementLinux.
  ///
  /// In it, this message translates to:
  /// **'Toolchain desktop Linux.'**
  String get onboardingPlatformRequirementLinux;

  /// No description provided for @onboardingAcceptanceLabel.
  ///
  /// In it, this message translates to:
  /// **'Confermo di aver verificato i prerequisiti e voglio proseguire'**
  String get onboardingAcceptanceLabel;

  /// No description provided for @onboardingContinue.
  ///
  /// In it, this message translates to:
  /// **'Continua'**
  String get onboardingContinue;

  /// No description provided for @homeTitle.
  ///
  /// In it, this message translates to:
  /// **'Bootstrap progetto'**
  String get homeTitle;

  /// No description provided for @homeStepProjectTitle.
  ///
  /// In it, this message translates to:
  /// **'Progetto'**
  String get homeStepProjectTitle;

  /// No description provided for @homeStepProjectSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Percorso e nomi dell\'app'**
  String get homeStepProjectSubtitle;

  /// No description provided for @homeTargetRootLabel.
  ///
  /// In it, this message translates to:
  /// **'Cartella di destinazione'**
  String get homeTargetRootLabel;

  /// No description provided for @homeTargetRootHelper.
  ///
  /// In it, this message translates to:
  /// **'Lascia vuoto per usare la directory corrente, oppure seleziona una cartella di destinazione esistente e sicura.'**
  String get homeTargetRootHelper;

  /// No description provided for @homeTargetRootRequiredError.
  ///
  /// In it, this message translates to:
  /// **'Il target root è obbligatorio.'**
  String get homeTargetRootRequiredError;

  /// No description provided for @homeTargetRootNotFoundError.
  ///
  /// In it, this message translates to:
  /// **'La directory target non esiste.'**
  String get homeTargetRootNotFoundError;

  /// No description provided for @homeTargetRootNotDirectoryError.
  ///
  /// In it, this message translates to:
  /// **'Il target root deve essere una directory, non un file.'**
  String get homeTargetRootNotDirectoryError;

  /// No description provided for @homeTargetRootNotResolvableError.
  ///
  /// In it, this message translates to:
  /// **'Il target root non può essere risolto in un percorso assoluto valido.'**
  String get homeTargetRootNotResolvableError;

  /// No description provided for @homeTargetRootNotAccessibleError.
  ///
  /// In it, this message translates to:
  /// **'La directory target deve essere leggibile, scrivibile e attraversabile.'**
  String get homeTargetRootNotAccessibleError;

  /// No description provided for @homeTargetRootUnsafeFilesystemRootError.
  ///
  /// In it, this message translates to:
  /// **'La root del filesystem non è una destinazione valida.'**
  String get homeTargetRootUnsafeFilesystemRootError;

  /// No description provided for @homeTargetRootUnsafeUserHomeError.
  ///
  /// In it, this message translates to:
  /// **'La home utente non è una destinazione valida.'**
  String get homeTargetRootUnsafeUserHomeError;

  /// No description provided for @homeTargetRootUnsafeHighLevelDirectoryError.
  ///
  /// In it, this message translates to:
  /// **'Scegli una directory più specifica e meno alta nella gerarchia.'**
  String get homeTargetRootUnsafeHighLevelDirectoryError;

  /// No description provided for @homeTargetRootSameAsBootstrapRepositoryError.
  ///
  /// In it, this message translates to:
  /// **'La directory del bootstrap non può essere usata come target root.'**
  String get homeTargetRootSameAsBootstrapRepositoryError;

  /// No description provided for @homeTargetRootExistingFlutterProjectError.
  ///
  /// In it, this message translates to:
  /// **'La directory contiene già un progetto Flutter.'**
  String get homeTargetRootExistingFlutterProjectError;

  /// No description provided for @homeTargetRootPartialFlutterProjectError.
  ///
  /// In it, this message translates to:
  /// **'La directory contiene tracce parziali di un progetto Flutter.'**
  String get homeTargetRootPartialFlutterProjectError;

  /// No description provided for @homeTargetRootUnsupportedContentsError.
  ///
  /// In it, this message translates to:
  /// **'La directory deve essere vuota o contenere solo file tollerati come README.md, .gitignore, LICENSE o la cartella .git.'**
  String get homeTargetRootUnsupportedContentsError;

  /// No description provided for @homeTargetRootInternalTemporaryDirectoryError.
  ///
  /// In it, this message translates to:
  /// **'La directory target non può essere una directory temporanea interna del bootstrap.'**
  String get homeTargetRootInternalTemporaryDirectoryError;

  /// No description provided for @homeChooseFolderTooltip.
  ///
  /// In it, this message translates to:
  /// **'Scegli cartella'**
  String get homeChooseFolderTooltip;

  /// No description provided for @homeProjectNameLabel.
  ///
  /// In it, this message translates to:
  /// **'Nome progetto'**
  String get homeProjectNameLabel;

  /// No description provided for @homeProjectNameHelper.
  ///
  /// In it, this message translates to:
  /// **'Usato per generare i nomi tecnici del progetto, come package Flutter e identificatori di piattaforma.'**
  String get homeProjectNameHelper;

  /// No description provided for @homeProjectNameRequiredError.
  ///
  /// In it, this message translates to:
  /// **'Il nome progetto è obbligatorio.'**
  String get homeProjectNameRequiredError;

  /// No description provided for @homeProjectNameTooLongError.
  ///
  /// In it, this message translates to:
  /// **'Il nome progetto è troppo lungo. Usa al massimo 80 caratteri.'**
  String get homeProjectNameTooLongError;

  /// No description provided for @homeProjectNameInvalidCharactersError.
  ///
  /// In it, this message translates to:
  /// **'Il nome progetto può contenere solo lettere, trattino (-) e underscore (_).'**
  String get homeProjectNameInvalidCharactersError;

  /// No description provided for @homeProjectNameInvalidDerivedFlutterNameError.
  ///
  /// In it, this message translates to:
  /// **'Il nome progetto non genera un package Flutter/Dart valido.'**
  String get homeProjectNameInvalidDerivedFlutterNameError;

  /// No description provided for @homeProjectNameDerivedStartsWithDigitError.
  ///
  /// In it, this message translates to:
  /// **'Il nome progetto genera un identificatore tecnico che inizia con un numero.'**
  String get homeProjectNameDerivedStartsWithDigitError;

  /// No description provided for @homeProjectNameInvalidDerivedPlatformIdentifierError.
  ///
  /// In it, this message translates to:
  /// **'Il nome progetto non genera identificatori Android/iOS validi.'**
  String get homeProjectNameInvalidDerivedPlatformIdentifierError;

  /// No description provided for @homeProjectNameDerivedTooWeakError.
  ///
  /// In it, this message translates to:
  /// **'Il nome progetto genera identificatori troppo deboli o insignificanti.'**
  String get homeProjectNameDerivedTooWeakError;

  /// No description provided for @homeProjectNameDerivedTooLongError.
  ///
  /// In it, this message translates to:
  /// **'Il nome progetto genera identificatori tecnici troppo lunghi.'**
  String get homeProjectNameDerivedTooLongError;

  /// No description provided for @homeAppDisplayNameLabel.
  ///
  /// In it, this message translates to:
  /// **'Nome visualizzato dell\'app'**
  String get homeAppDisplayNameLabel;

  /// No description provided for @homeAppDisplayNameHint.
  ///
  /// In it, this message translates to:
  /// **'Mia App'**
  String get homeAppDisplayNameHint;

  /// No description provided for @homeAppDisplayNameHelper.
  ///
  /// In it, this message translates to:
  /// **'Usato come nome mostrato all\'utente dentro il codice generato e nell\'app finale.'**
  String get homeAppDisplayNameHelper;

  /// No description provided for @homeAppDisplayNameRequiredError.
  ///
  /// In it, this message translates to:
  /// **'Il nome visualizzato dell\'app è obbligatorio.'**
  String get homeAppDisplayNameRequiredError;

  /// No description provided for @homeAppDisplayNameTooLongError.
  ///
  /// In it, this message translates to:
  /// **'Il nome visualizzato dell\'app è troppo lungo. Usa al massimo 60 caratteri.'**
  String get homeAppDisplayNameTooLongError;

  /// No description provided for @homeAppDisplayNameLeadingOrTrailingWhitespaceError.
  ///
  /// In it, this message translates to:
  /// **'Il nome visualizzato dell\'app non deve avere spazi iniziali o finali.'**
  String get homeAppDisplayNameLeadingOrTrailingWhitespaceError;

  /// No description provided for @homeAppDisplayNameContainsNewlineError.
  ///
  /// In it, this message translates to:
  /// **'Il nome visualizzato dell\'app non può contenere ritorni a capo.'**
  String get homeAppDisplayNameContainsNewlineError;

  /// No description provided for @homeAppDisplayNameContainsControlCharacterError.
  ///
  /// In it, this message translates to:
  /// **'Il nome visualizzato dell\'app contiene caratteri di controllo non supportati.'**
  String get homeAppDisplayNameContainsControlCharacterError;

  /// No description provided for @homeAppDisplayNameContainsSingleQuoteError.
  ///
  /// In it, this message translates to:
  /// **'Il nome visualizzato dell\'app non può contenere apici singoli.'**
  String get homeAppDisplayNameContainsSingleQuoteError;

  /// No description provided for @homeAppDisplayNameContainsBackslashError.
  ///
  /// In it, this message translates to:
  /// **'Il nome visualizzato dell\'app non può contenere backslash.'**
  String get homeAppDisplayNameContainsBackslashError;

  /// No description provided for @homeAppDisplayNameNoVisibleCharacterError.
  ///
  /// In it, this message translates to:
  /// **'Il nome visualizzato dell\'app deve contenere almeno un carattere visibile.'**
  String get homeAppDisplayNameNoVisibleCharacterError;

  /// No description provided for @homeOrganizationIdLabel.
  ///
  /// In it, this message translates to:
  /// **'Organization ID'**
  String get homeOrganizationIdLabel;

  /// No description provided for @homeOrganizationIdHint.
  ///
  /// In it, this message translates to:
  /// **'com.example'**
  String get homeOrganizationIdHint;

  /// No description provided for @homeOrganizationIdHelper.
  ///
  /// In it, this message translates to:
  /// **'Identificatore reverse-domain obbligatorio usato come base per gli identificatori Android e Apple.'**
  String get homeOrganizationIdHelper;

  /// No description provided for @homeOrganizationIdRequiredError.
  ///
  /// In it, this message translates to:
  /// **'L\'organization ID è obbligatorio.'**
  String get homeOrganizationIdRequiredError;

  /// No description provided for @homeOrganizationIdTooLongError.
  ///
  /// In it, this message translates to:
  /// **'L\'organization ID è troppo lungo. Usa al massimo 120 caratteri.'**
  String get homeOrganizationIdTooLongError;

  /// No description provided for @homeOrganizationIdLeadingOrTrailingWhitespaceError.
  ///
  /// In it, this message translates to:
  /// **'L\'organization ID non deve avere spazi iniziali o finali.'**
  String get homeOrganizationIdLeadingOrTrailingWhitespaceError;

  /// No description provided for @homeOrganizationIdInvalidFormatError.
  ///
  /// In it, this message translates to:
  /// **'L\'organization ID deve usare il formato reverse-domain, per esempio com.example o it.company.app.'**
  String get homeOrganizationIdInvalidFormatError;

  /// No description provided for @homeStepPlatformsTitle.
  ///
  /// In it, this message translates to:
  /// **'Piattaforme'**
  String get homeStepPlatformsTitle;

  /// No description provided for @homeStepPlatformsSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Seleziona le piattaforme target'**
  String get homeStepPlatformsSubtitle;

  /// No description provided for @homePlatformsRequiredError.
  ///
  /// In it, this message translates to:
  /// **'Seleziona almeno una piattaforma target.'**
  String get homePlatformsRequiredError;

  /// No description provided for @homeStepEnvironmentsTitle.
  ///
  /// In it, this message translates to:
  /// **'Ambienti'**
  String get homeStepEnvironmentsTitle;

  /// No description provided for @homeStepEnvironmentsSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Selezionane almeno due'**
  String get homeStepEnvironmentsSubtitle;

  /// No description provided for @homeCustomEnvironmentLabel.
  ///
  /// In it, this message translates to:
  /// **'Ambiente personalizzato'**
  String get homeCustomEnvironmentLabel;

  /// No description provided for @homeCustomEnvironmentHint.
  ///
  /// In it, this message translates to:
  /// **'staging'**
  String get homeCustomEnvironmentHint;

  /// No description provided for @homeAddEnvironment.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi'**
  String get homeAddEnvironment;

  /// No description provided for @homeEnvironmentsRequiredError.
  ///
  /// In it, this message translates to:
  /// **'Seleziona almeno due ambienti.'**
  String get homeEnvironmentsRequiredError;

  /// No description provided for @homeStepRouterTitle.
  ///
  /// In it, this message translates to:
  /// **'Router'**
  String get homeStepRouterTitle;

  /// No description provided for @homeStepRouterSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Scegli la forma del router'**
  String get homeStepRouterSubtitle;

  /// No description provided for @homeRouterShapeRequiredError.
  ///
  /// In it, this message translates to:
  /// **'Seleziona una forma del router.'**
  String get homeRouterShapeRequiredError;

  /// No description provided for @homeCollectedValuesTitle.
  ///
  /// In it, this message translates to:
  /// **'Valori raccolti'**
  String get homeCollectedValuesTitle;

  /// No description provided for @homeContinue.
  ///
  /// In it, this message translates to:
  /// **'Continua'**
  String get homeContinue;

  /// No description provided for @homeFinish.
  ///
  /// In it, this message translates to:
  /// **'Fine'**
  String get homeFinish;

  /// No description provided for @homeBack.
  ///
  /// In it, this message translates to:
  /// **'Indietro'**
  String get homeBack;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
