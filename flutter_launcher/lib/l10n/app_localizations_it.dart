// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'App';

  @override
  String get onboardingTitle => 'Flutter Launcher';

  @override
  String get onboardingHeading => 'Prerequisiti per creare un progetto Flutter';

  @override
  String get onboardingDescription =>
      'Questo launcher eseguirà i comandi necessari per creare un progetto Flutter da zero. Prima di continuare, verifica che questi prerequisiti siano soddisfatti.';

  @override
  String get onboardingPrerequisitesTitle => 'Prerequisiti';

  @override
  String get onboardingRequirementFvm =>
      'FVM funzionante e disponibile nel PATH.';

  @override
  String get onboardingRequirementInternet => 'Accesso a internet.';

  @override
  String get onboardingRequirementShell =>
      'bash su Unix/macOS oppure cmd e PowerShell su Windows.';

  @override
  String get onboardingRequirementTargetDirectory =>
      'Esiste una directory target e non è già occupata da un progetto Flutter.';

  @override
  String get onboardingToolchainsTitle => 'Toolchain per piattaforma';

  @override
  String get onboardingToolchainsDescription =>
      'Se selezioni certe piattaforme, servono anche le relative toolchain Flutter.';

  @override
  String get onboardingPlatformAndroid => 'android';

  @override
  String get onboardingPlatformRequirementAndroid =>
      'Android SDK + toolchain Android.';

  @override
  String get onboardingPlatformIos => 'ios';

  @override
  String get onboardingPlatformRequirementIos =>
      'macOS + Xcode + toolchain iOS.';

  @override
  String get onboardingPlatformMacos => 'macos';

  @override
  String get onboardingPlatformRequirementMacos => 'macOS + Xcode.';

  @override
  String get onboardingPlatformWeb => 'web';

  @override
  String get onboardingPlatformRequirementWeb =>
      'Toolchain web supportata da Flutter.';

  @override
  String get onboardingPlatformWindows => 'windows';

  @override
  String get onboardingPlatformRequirementWindows =>
      'Toolchain desktop Windows.';

  @override
  String get onboardingPlatformLinux => 'linux';

  @override
  String get onboardingPlatformRequirementLinux => 'Toolchain desktop Linux.';

  @override
  String get onboardingAcceptanceLabel =>
      'Confermo di aver verificato i prerequisiti e voglio proseguire';

  @override
  String get onboardingContinue => 'Continua';

  @override
  String get homeTitle => 'Bootstrap progetto';

  @override
  String get homeStepProjectTitle => 'Progetto';

  @override
  String get homeStepProjectSubtitle => 'Percorso e nomi dell\'app';

  @override
  String get homeTargetRootLabel => 'Cartella di destinazione';

  @override
  String get homeTargetRootHelper =>
      'Lascia vuoto per usare la directory corrente, oppure seleziona una cartella di destinazione esistente e sicura.';

  @override
  String get homeTargetRootRequiredError => 'Il target root è obbligatorio.';

  @override
  String get homeTargetRootNotFoundError => 'La directory target non esiste.';

  @override
  String get homeTargetRootNotDirectoryError =>
      'Il target root deve essere una directory, non un file.';

  @override
  String get homeTargetRootNotResolvableError =>
      'Il target root non può essere risolto in un percorso assoluto valido.';

  @override
  String get homeTargetRootNotAccessibleError =>
      'La directory target deve essere leggibile, scrivibile e attraversabile.';

  @override
  String get homeTargetRootUnsafeFilesystemRootError =>
      'La root del filesystem non è una destinazione valida.';

  @override
  String get homeTargetRootUnsafeUserHomeError =>
      'La home utente non è una destinazione valida.';

  @override
  String get homeTargetRootUnsafeHighLevelDirectoryError =>
      'Scegli una directory più specifica e meno alta nella gerarchia.';

  @override
  String get homeTargetRootSameAsBootstrapRepositoryError =>
      'La directory del bootstrap non può essere usata come target root.';

  @override
  String get homeTargetRootExistingFlutterProjectError =>
      'La directory contiene già un progetto Flutter.';

  @override
  String get homeTargetRootPartialFlutterProjectError =>
      'La directory contiene tracce parziali di un progetto Flutter.';

  @override
  String get homeTargetRootUnsupportedContentsError =>
      'La directory deve essere vuota o contenere solo file tollerati come README.md, .gitignore, LICENSE o la cartella .git.';

  @override
  String get homeTargetRootInternalTemporaryDirectoryError =>
      'La directory target non può essere una directory temporanea interna del bootstrap.';

  @override
  String get homeChooseFolderTooltip => 'Scegli cartella';

  @override
  String get homeProjectNameLabel => 'Nome progetto';

  @override
  String get homeProjectNameHelper =>
      'Usato per generare i nomi tecnici del progetto, come package Flutter e identificatori di piattaforma.';

  @override
  String get homeProjectNameRequiredError => 'Il nome progetto è obbligatorio.';

  @override
  String get homeProjectNameTooLongError =>
      'Il nome progetto è troppo lungo. Usa al massimo 80 caratteri.';

  @override
  String get homeProjectNameInvalidCharactersError =>
      'Il nome progetto può contenere solo lettere, trattino (-) e underscore (_).';

  @override
  String get homeProjectNameInvalidDerivedFlutterNameError =>
      'Il nome progetto non genera un package Flutter/Dart valido.';

  @override
  String get homeProjectNameDerivedStartsWithDigitError =>
      'Il nome progetto genera un identificatore tecnico che inizia con un numero.';

  @override
  String get homeProjectNameInvalidDerivedPlatformIdentifierError =>
      'Il nome progetto non genera identificatori Android/iOS validi.';

  @override
  String get homeProjectNameDerivedTooWeakError =>
      'Il nome progetto genera identificatori troppo deboli o insignificanti.';

  @override
  String get homeProjectNameDerivedTooLongError =>
      'Il nome progetto genera identificatori tecnici troppo lunghi.';

  @override
  String get homeAppDisplayNameLabel => 'Nome visualizzato dell\'app';

  @override
  String get homeAppDisplayNameHint => 'Mia App';

  @override
  String get homeAppDisplayNameHelper =>
      'Usato come nome mostrato all\'utente dentro il codice generato e nell\'app finale.';

  @override
  String get homeAppDisplayNameRequiredError =>
      'Il nome visualizzato dell\'app è obbligatorio.';

  @override
  String get homeAppDisplayNameTooLongError =>
      'Il nome visualizzato dell\'app è troppo lungo. Usa al massimo 60 caratteri.';

  @override
  String get homeAppDisplayNameLeadingOrTrailingWhitespaceError =>
      'Il nome visualizzato dell\'app non deve avere spazi iniziali o finali.';

  @override
  String get homeAppDisplayNameContainsNewlineError =>
      'Il nome visualizzato dell\'app non può contenere ritorni a capo.';

  @override
  String get homeAppDisplayNameContainsControlCharacterError =>
      'Il nome visualizzato dell\'app contiene caratteri di controllo non supportati.';

  @override
  String get homeAppDisplayNameContainsSingleQuoteError =>
      'Il nome visualizzato dell\'app non può contenere apici singoli.';

  @override
  String get homeAppDisplayNameContainsBackslashError =>
      'Il nome visualizzato dell\'app non può contenere backslash.';

  @override
  String get homeAppDisplayNameNoVisibleCharacterError =>
      'Il nome visualizzato dell\'app deve contenere almeno un carattere visibile.';

  @override
  String get homeOrganizationIdLabel => 'Organization ID';

  @override
  String get homeOrganizationIdHint => 'com.example';

  @override
  String get homeOrganizationIdHelper =>
      'Identificatore reverse-domain obbligatorio usato come base per gli identificatori Android e Apple.';

  @override
  String get homeOrganizationIdRequiredError =>
      'L\'organization ID è obbligatorio.';

  @override
  String get homeOrganizationIdTooLongError =>
      'L\'organization ID è troppo lungo. Usa al massimo 120 caratteri.';

  @override
  String get homeOrganizationIdLeadingOrTrailingWhitespaceError =>
      'L\'organization ID non deve avere spazi iniziali o finali.';

  @override
  String get homeOrganizationIdInvalidFormatError =>
      'L\'organization ID deve usare il formato reverse-domain, per esempio com.example o it.company.app.';

  @override
  String get homeStepPlatformsTitle => 'Piattaforme';

  @override
  String get homeStepPlatformsSubtitle => 'Seleziona le piattaforme target';

  @override
  String get homePlatformsRequiredError =>
      'Seleziona almeno una piattaforma target.';

  @override
  String get homeStepEnvironmentsTitle => 'Ambienti';

  @override
  String get homeStepEnvironmentsSubtitle => 'Selezionane almeno due';

  @override
  String get homeCustomEnvironmentLabel => 'Ambiente personalizzato';

  @override
  String get homeCustomEnvironmentHint => 'staging';

  @override
  String get homeAddEnvironment => 'Aggiungi';

  @override
  String get homeEnvironmentsRequiredError => 'Seleziona almeno due ambienti.';

  @override
  String get homeStepRouterTitle => 'Router';

  @override
  String get homeStepRouterSubtitle => 'Scegli la forma del router';

  @override
  String get homeRouterShapeRequiredError => 'Seleziona una forma del router.';

  @override
  String get homeCollectedValuesTitle => 'Valori raccolti';

  @override
  String get homeContinue => 'Continua';

  @override
  String get homeFinish => 'Fine';

  @override
  String get homeBack => 'Indietro';
}
