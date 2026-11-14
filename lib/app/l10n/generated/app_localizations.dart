import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
  static const List<Locale> supportedLocales = <Locale>[Locale('fr')];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'DocuSafe'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In fr, this message translates to:
  /// **'Vos documents, protégés.'**
  String get appTagline;

  /// No description provided for @secureLabel.
  ///
  /// In fr, this message translates to:
  /// **'Chiffré sur cet appareil'**
  String get secureLabel;

  /// No description provided for @secureLabelPlural.
  ///
  /// In fr, this message translates to:
  /// **'Chiffrés sur cet appareil'**
  String get secureLabelPlural;

  /// No description provided for @commonNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get commonNext;

  /// No description provided for @commonSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get commonSkip;

  /// No description provided for @commonContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get commonContinue;

  /// No description provided for @commonCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get commonRetry;

  /// No description provided for @commonLater.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get commonLater;

  /// No description provided for @commonCopy.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get commonCopy;

  /// No description provided for @commonCopied.
  ///
  /// In fr, this message translates to:
  /// **'Copié. Le presse-papiers sera vidé dans une minute.'**
  String get commonCopied;

  /// No description provided for @commonBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get commonBack;

  /// No description provided for @commonDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get commonDelete;

  /// No description provided for @commonConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get commonConfirm;

  /// No description provided for @commonSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get commonSave;

  /// No description provided for @commonDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get commonDone;

  /// No description provided for @commonErrorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get commonErrorTitle;

  /// No description provided for @commonErrorBody.
  ///
  /// In fr, this message translates to:
  /// **'L\'opération n\'a pas pu aboutir. Réessayez dans un instant.'**
  String get commonErrorBody;

  /// No description provided for @onboardingTitle1.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue dans DocuSafe'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In fr, this message translates to:
  /// **'Le coffre-fort de vos documents importants : pièces d\'identité, diplômes, contrats, factures.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In fr, this message translates to:
  /// **'Tout reste sur votre téléphone'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In fr, this message translates to:
  /// **'Pas de compte à créer, pas de serveur. DocuSafe fonctionne sans connexion Internet.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In fr, this message translates to:
  /// **'Chiffré et protégé par votre code'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In fr, this message translates to:
  /// **'Chaque document est chiffré. Sans votre code ou votre empreinte, personne ne peut le lire.'**
  String get onboardingBody3;

  /// No description provided for @onboardingTitle4.
  ///
  /// In fr, this message translates to:
  /// **'Vos documents vous appartiennent'**
  String get onboardingTitle4;

  /// No description provided for @onboardingBody4.
  ///
  /// In fr, this message translates to:
  /// **'Aucune publicité, aucun suivi. Rien ne quitte votre téléphone sans votre accord.'**
  String get onboardingBody4;

  /// No description provided for @onboardingPrivacyLink.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get onboardingPrivacyLink;

  /// No description provided for @onboardingTermsLink.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get onboardingTermsLink;

  /// No description provided for @onboardingCreateVault.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon coffre-fort'**
  String get onboardingCreateVault;

  /// No description provided for @onboardingPageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Page {current} sur {total}'**
  String onboardingPageLabel(int current, int total);

  /// No description provided for @setupStep.
  ///
  /// In fr, this message translates to:
  /// **'Étape {step} sur {total}'**
  String setupStep(int step, int total);

  /// No description provided for @setupPinTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre code'**
  String get setupPinTitle;

  /// No description provided for @setupPinBody.
  ///
  /// In fr, this message translates to:
  /// **'6 chiffres ou plus. Ce code protège tous vos documents.'**
  String get setupPinBody;

  /// No description provided for @setupPinHint.
  ///
  /// In fr, this message translates to:
  /// **'Évitez les suites simples comme 123456.'**
  String get setupPinHint;

  /// No description provided for @setupPinConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez votre code'**
  String get setupPinConfirmTitle;

  /// No description provided for @setupPinConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le même code une seconde fois.'**
  String get setupPinConfirmBody;

  /// No description provided for @setupPinTooSimple.
  ///
  /// In fr, this message translates to:
  /// **'Ce code est trop simple. Choisissez-en un autre.'**
  String get setupPinTooSimple;

  /// No description provided for @setupPinTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Le code doit avoir au moins 6 chiffres.'**
  String get setupPinTooShort;

  /// No description provided for @setupPinMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les deux codes ne sont pas identiques. Recommencez.'**
  String get setupPinMismatch;

  /// No description provided for @setupPreparing.
  ///
  /// In fr, this message translates to:
  /// **'Préparation de votre coffre…'**
  String get setupPreparing;

  /// No description provided for @homeRecoveryBanner.
  ///
  /// In fr, this message translates to:
  /// **'Votre clé de récupération n\'est pas encore notée. Sans elle, un code oublié signifie des documents perdus.'**
  String get homeRecoveryBanner;

  /// No description provided for @homeRecoveryAction.
  ///
  /// In fr, this message translates to:
  /// **'Noter ma clé'**
  String get homeRecoveryAction;

  /// No description provided for @settingsRecoveryKeyTodo.
  ///
  /// In fr, this message translates to:
  /// **'À noter dès maintenant'**
  String get settingsRecoveryKeyTodo;

  /// No description provided for @setupRecoveryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre clé de récupération'**
  String get setupRecoveryTitle;

  /// No description provided for @setupRecoveryBody.
  ///
  /// In fr, this message translates to:
  /// **'Elle permet de retrouver l\'accès si vous oubliez votre code. Notez-la et gardez-la ailleurs que sur ce téléphone.'**
  String get setupRecoveryBody;

  /// No description provided for @setupRecoveryWarning.
  ///
  /// In fr, this message translates to:
  /// **'Sans votre code et sans cette clé, vos documents seront définitivement perdus. Personne ne pourra les récupérer.'**
  String get setupRecoveryWarning;

  /// No description provided for @setupRecoveryChecked.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai conservé ma clé en lieu sûr'**
  String get setupRecoveryChecked;

  /// No description provided for @setupRecoveryKeySemantics.
  ///
  /// In fr, this message translates to:
  /// **'Clé de récupération : {key}'**
  String setupRecoveryKeySemantics(String key);

  /// No description provided for @setupBiometricTitle.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller plus vite ?'**
  String get setupBiometricTitle;

  /// No description provided for @setupBiometricBody.
  ///
  /// In fr, this message translates to:
  /// **'Utilisez {method} pour ouvrir DocuSafe. Votre code reste toujours valable.'**
  String setupBiometricBody(String method);

  /// No description provided for @setupBiometricEnable.
  ///
  /// In fr, this message translates to:
  /// **'Activer {method}'**
  String setupBiometricEnable(String method);

  /// No description provided for @setupBiometricFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le déverrouillage rapide n\'a pas pu être activé. Vous pourrez réessayer dans les paramètres.'**
  String get setupBiometricFailed;

  /// No description provided for @biometricFingerprint.
  ///
  /// In fr, this message translates to:
  /// **'l\'empreinte'**
  String get biometricFingerprint;

  /// No description provided for @biometricFingerprintTitle.
  ///
  /// In fr, this message translates to:
  /// **'Empreinte digitale'**
  String get biometricFingerprintTitle;

  /// No description provided for @biometricFace.
  ///
  /// In fr, this message translates to:
  /// **'la reconnaissance du visage'**
  String get biometricFace;

  /// No description provided for @biometricFaceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Reconnaissance du visage'**
  String get biometricFaceTitle;

  /// No description provided for @biometricFaceId.
  ///
  /// In fr, this message translates to:
  /// **'Face ID'**
  String get biometricFaceId;

  /// No description provided for @biometricTouchId.
  ///
  /// In fr, this message translates to:
  /// **'Touch ID'**
  String get biometricTouchId;

  /// No description provided for @biometricGeneric.
  ///
  /// In fr, this message translates to:
  /// **'la biométrie'**
  String get biometricGeneric;

  /// No description provided for @biometricGenericTitle.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouillage biométrique'**
  String get biometricGenericTitle;

  /// No description provided for @unlockTitle.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre code'**
  String get unlockTitle;

  /// No description provided for @unlockBiometricReason.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller DocuSafe'**
  String get unlockBiometricReason;

  /// No description provided for @unlockWrongPin.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect. {remaining, plural, =0{Dernier essai avant une attente.} =1{Il reste 1 essai.} other{Il reste {remaining} essais.}}'**
  String unlockWrongPin(int remaining);

  /// No description provided for @unlockTooManyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Trop d\'essais'**
  String get unlockTooManyTitle;

  /// No description provided for @unlockTooManyBody.
  ///
  /// In fr, this message translates to:
  /// **'Par sécurité, patientez avant de réessayer.'**
  String get unlockTooManyBody;

  /// No description provided for @unlockRetryIn.
  ///
  /// In fr, this message translates to:
  /// **'Réessayez dans {delay}'**
  String unlockRetryIn(String delay);

  /// No description provided for @unlockForgotPin.
  ///
  /// In fr, this message translates to:
  /// **'Code oublié ?'**
  String get unlockForgotPin;

  /// No description provided for @unlockUseRecoveryKey.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser ma clé de récupération'**
  String get unlockUseRecoveryKey;

  /// No description provided for @unlockBiometricChanged.
  ///
  /// In fr, this message translates to:
  /// **'Votre biométrie a changé. Saisissez votre code.'**
  String get unlockBiometricChanged;

  /// No description provided for @unlockBiometricButton.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller avec {method}'**
  String unlockBiometricButton(String method);

  /// No description provided for @unlockSlotMissing.
  ///
  /// In fr, this message translates to:
  /// **'Le stockage sécurisé du téléphone est endommagé. Utilisez votre clé de récupération.'**
  String get unlockSlotMissing;

  /// No description provided for @recoveryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code oublié'**
  String get recoveryTitle;

  /// No description provided for @recoveryBody.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez la clé de récupération affichée à la création de votre coffre.'**
  String get recoveryBody;

  /// No description provided for @recoveryFieldLabel.
  ///
  /// In fr, this message translates to:
  /// **'Clé de récupération'**
  String get recoveryFieldLabel;

  /// No description provided for @recoveryCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} caractères sur {total}'**
  String recoveryCount(int count, int total);

  /// No description provided for @recoveryInfo.
  ///
  /// In fr, this message translates to:
  /// **'Vous choisirez ensuite un nouveau code. Vos documents ne changent pas.'**
  String get recoveryInfo;

  /// No description provided for @recoveryVerify.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier la clé'**
  String get recoveryVerify;

  /// No description provided for @recoveryInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Cette clé n\'est pas reconnue. Vérifiez chaque caractère.'**
  String get recoveryInvalid;

  /// No description provided for @recoveryNewPinTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un nouveau code'**
  String get recoveryNewPinTitle;

  /// No description provided for @recoveryNewPinBody.
  ///
  /// In fr, this message translates to:
  /// **'6 chiffres ou plus. Il remplace l\'ancien code.'**
  String get recoveryNewPinBody;

  /// No description provided for @durationSeconds.
  ///
  /// In fr, this message translates to:
  /// **'{count} s'**
  String durationSeconds(int count);

  /// No description provided for @durationMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{count} min'**
  String durationMinutes(int count);

  /// No description provided for @durationMinutesSeconds.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min {seconds} s'**
  String durationMinutesSeconds(int minutes, int seconds);

  /// No description provided for @homeDocumentCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun document} =1{1 document} other{{count} documents}}'**
  String homeDocumentCount(int count);

  /// No description provided for @homeLock.
  ///
  /// In fr, this message translates to:
  /// **'Verrouiller'**
  String get homeLock;

  /// No description provided for @homeSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get homeSettings;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre coffre est vide'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Le scanner et l\'importation arrivent à la prochaine étape du développement. Votre coffre est prêt : code, chiffrement et catégories sont en place.'**
  String get homeEmptyBody;

  /// No description provided for @homeCategories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get homeCategories;

  /// No description provided for @homeCategoryCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun document} =1{1 document} other{{count} documents}}'**
  String homeCategoryCount(int count);

  /// No description provided for @settingsSecurityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get settingsSecurityTitle;

  /// No description provided for @settingsChangePin.
  ///
  /// In fr, this message translates to:
  /// **'Changer le code'**
  String get settingsChangePin;

  /// No description provided for @settingsBiometricSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller avec {method}'**
  String settingsBiometricSubtitle(String method);

  /// No description provided for @settingsBiometricUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Non disponible sur ce téléphone'**
  String get settingsBiometricUnavailable;

  /// No description provided for @settingsRecoveryKey.
  ///
  /// In fr, this message translates to:
  /// **'Clé de récupération'**
  String get settingsRecoveryKey;

  /// No description provided for @settingsRecoveryKeySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer une nouvelle clé'**
  String get settingsRecoveryKeySubtitle;

  /// No description provided for @settingsRecoveryKeyNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle clé de récupération'**
  String get settingsRecoveryKeyNewTitle;

  /// No description provided for @settingsRecoveryKeyNewBody.
  ///
  /// In fr, this message translates to:
  /// **'L\'ancienne clé ne fonctionne plus. Notez celle-ci et gardez-la ailleurs que sur ce téléphone.'**
  String get settingsRecoveryKeyNewBody;

  /// No description provided for @settingsLockSection.
  ///
  /// In fr, this message translates to:
  /// **'Verrouillage'**
  String get settingsLockSection;

  /// No description provided for @settingsAutoLock.
  ///
  /// In fr, this message translates to:
  /// **'Verrouillage automatique'**
  String get settingsAutoLock;

  /// No description provided for @settingsAutoLockSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Après {delay} sans action'**
  String settingsAutoLockSubtitle(String delay);

  /// No description provided for @settingsAutoLockChoice.
  ///
  /// In fr, this message translates to:
  /// **'Délai de verrouillage'**
  String get settingsAutoLockChoice;

  /// No description provided for @settingsScreenshots.
  ///
  /// In fr, this message translates to:
  /// **'Captures d\'écran'**
  String get settingsScreenshots;

  /// No description provided for @settingsScreenshotsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser les captures et l\'aperçu des applications récentes'**
  String get settingsScreenshotsSubtitle;

  /// No description provided for @settingsLockNow.
  ///
  /// In fr, this message translates to:
  /// **'Verrouiller maintenant'**
  String get settingsLockNow;

  /// No description provided for @settingsDangerSection.
  ///
  /// In fr, this message translates to:
  /// **'Zone sensible'**
  String get settingsDangerSection;

  /// No description provided for @settingsWipe.
  ///
  /// In fr, this message translates to:
  /// **'Effacer le coffre'**
  String get settingsWipe;

  /// No description provided for @settingsWipeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprime définitivement tous les documents'**
  String get settingsWipeSubtitle;

  /// No description provided for @settingsWipeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Effacer le coffre ?'**
  String get settingsWipeTitle;

  /// No description provided for @settingsWipeBody.
  ///
  /// In fr, this message translates to:
  /// **'Tous vos documents, catégories et réglages seront supprimés de ce téléphone. Cette action est définitive. Pour confirmer, écrivez EFFACER.'**
  String get settingsWipeBody;

  /// No description provided for @settingsWipeConfirmWord.
  ///
  /// In fr, this message translates to:
  /// **'EFFACER'**
  String get settingsWipeConfirmWord;

  /// No description provided for @settingsWipeFieldLabel.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez EFFACER'**
  String get settingsWipeFieldLabel;

  /// No description provided for @settingsWipeAction.
  ///
  /// In fr, this message translates to:
  /// **'Effacer définitivement'**
  String get settingsWipeAction;

  /// No description provided for @settingsPinChanged.
  ///
  /// In fr, this message translates to:
  /// **'Votre code a été changé.'**
  String get settingsPinChanged;

  /// No description provided for @settingsBiometricEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Le déverrouillage rapide est activé.'**
  String get settingsBiometricEnabled;

  /// No description provided for @settingsBiometricDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Le déverrouillage rapide est désactivé.'**
  String get settingsBiometricDisabled;

  /// No description provided for @changePinTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau code'**
  String get changePinTitle;

  /// No description provided for @changePinBody.
  ///
  /// In fr, this message translates to:
  /// **'6 chiffres ou plus. Il remplace l\'ancien code.'**
  String get changePinBody;

  /// No description provided for @reauthTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez votre identité'**
  String get reauthTitle;

  /// No description provided for @reauthBody.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre code pour continuer.'**
  String get reauthBody;

  /// No description provided for @reauthBiometricReason.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer l\'opération'**
  String get reauthBiometricReason;

  /// No description provided for @legalPrivacyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get legalPrivacyTitle;

  /// No description provided for @legalTermsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get legalTermsTitle;

  /// No description provided for @legalDraftNotice.
  ///
  /// In fr, this message translates to:
  /// **'Version provisoire. Ce texte sera relu avant la publication de l\'application.'**
  String get legalDraftNotice;

  /// No description provided for @dateToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get dateToday;

  /// No description provided for @dateYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get dateYesterday;

  /// No description provided for @dateTodayAt.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui à {time}'**
  String dateTodayAt(String time);

  /// No description provided for @expiryExpired.
  ///
  /// In fr, this message translates to:
  /// **'Expiré'**
  String get expiryExpired;

  /// No description provided for @expiryInDays.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =0{Aujourd\'hui} other{J-{days}}}'**
  String expiryInDays(int days);

  /// No description provided for @expiryInMonths.
  ///
  /// In fr, this message translates to:
  /// **'{months, plural, =1{1 mois} other{{months} mois}}'**
  String expiryInMonths(int months);

  /// No description provided for @expiryInYears.
  ///
  /// In fr, this message translates to:
  /// **'{years, plural, =1{1 an} other{{years} ans}}'**
  String expiryInYears(int years);

  /// No description provided for @expiryInYearsMonths.
  ///
  /// In fr, this message translates to:
  /// **'{years, plural, =1{1 an} other{{years} ans}} {months} mois'**
  String expiryInYearsMonths(int years, int months);

  /// No description provided for @expiresOn.
  ///
  /// In fr, this message translates to:
  /// **'Expire le {date}'**
  String expiresOn(String date);

  /// No description provided for @expiredOn.
  ///
  /// In fr, this message translates to:
  /// **'Expiré le {date}'**
  String expiredOn(String date);

  /// No description provided for @pageCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 page} other{{count} pages}}'**
  String pageCount(int count);

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navDocuments.
  ///
  /// In fr, this message translates to:
  /// **'Documents'**
  String get navDocuments;

  /// No description provided for @navScanner.
  ///
  /// In fr, this message translates to:
  /// **'Scanner'**
  String get navScanner;

  /// No description provided for @navDeadlines.
  ///
  /// In fr, this message translates to:
  /// **'Échéances'**
  String get navDeadlines;

  /// No description provided for @navSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get navSettings;

  /// No description provided for @homeImport.
  ///
  /// In fr, this message translates to:
  /// **'Importer un fichier'**
  String get homeImport;

  /// No description provided for @homeEmptyBodyLotA.
  ///
  /// In fr, this message translates to:
  /// **'Importez votre premier document. Il sera chiffré sur ce téléphone. Le scanner arrive à la prochaine étape du développement.'**
  String get homeEmptyBodyLotA;

  /// No description provided for @homeRecentlyAdded.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutés récemment'**
  String get homeRecentlyAdded;

  /// No description provided for @homeFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Favoris'**
  String get homeFavorites;

  /// No description provided for @homeSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get homeSeeAll;

  /// No description provided for @homeManage.
  ///
  /// In fr, this message translates to:
  /// **'Gérer'**
  String get homeManage;

  /// No description provided for @documentsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Documents'**
  String get documentsTitle;

  /// No description provided for @documentsTabAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get documentsTabAll;

  /// No description provided for @documentsTabFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Favoris'**
  String get documentsTabFavorites;

  /// No description provided for @documentsTabRecent.
  ///
  /// In fr, this message translates to:
  /// **'Récents'**
  String get documentsTabRecent;

  /// No description provided for @documentsAllCategories.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get documentsAllCategories;

  /// No description provided for @documentsSort.
  ///
  /// In fr, this message translates to:
  /// **'Trier'**
  String get documentsSort;

  /// No description provided for @documentsSortNewest.
  ///
  /// In fr, this message translates to:
  /// **'Plus récents d\'abord'**
  String get documentsSortNewest;

  /// No description provided for @documentsSortOldest.
  ///
  /// In fr, this message translates to:
  /// **'Plus anciens d\'abord'**
  String get documentsSortOldest;

  /// No description provided for @documentsSortTitle.
  ///
  /// In fr, this message translates to:
  /// **'Par nom'**
  String get documentsSortTitle;

  /// No description provided for @documentsSortExpiration.
  ///
  /// In fr, this message translates to:
  /// **'Par date d\'expiration'**
  String get documentsSortExpiration;

  /// No description provided for @documentsRecentAdded.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutés'**
  String get documentsRecentAdded;

  /// No description provided for @documentsRecentOpened.
  ///
  /// In fr, this message translates to:
  /// **'Consultés'**
  String get documentsRecentOpened;

  /// No description provided for @documentsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun document pour l\'instant'**
  String get documentsEmptyTitle;

  /// No description provided for @documentsEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Importez votre premier document. Il sera chiffré sur ce téléphone.'**
  String get documentsEmptyBody;

  /// No description provided for @documentsEmptyFilteredTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun document ici'**
  String get documentsEmptyFilteredTitle;

  /// No description provided for @documentsEmptyFilteredBody.
  ///
  /// In fr, this message translates to:
  /// **'Changez de catégorie ou retirez le filtre.'**
  String get documentsEmptyFilteredBody;

  /// No description provided for @documentsFavoritesEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun favori'**
  String get documentsFavoritesEmptyTitle;

  /// No description provided for @documentsFavoritesEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Touchez l\'étoile d\'un document pour le retrouver ici.'**
  String get documentsFavoritesEmptyBody;

  /// No description provided for @documentsRecentEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rien de récent'**
  String get documentsRecentEmptyTitle;

  /// No description provided for @documentsRecentEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Les documents ajoutés ou consultés apparaîtront ici.'**
  String get documentsRecentEmptyBody;

  /// No description provided for @documentsAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get documentsAdd;

  /// No description provided for @documentsAddFile.
  ///
  /// In fr, this message translates to:
  /// **'Importer un fichier'**
  String get documentsAddFile;

  /// No description provided for @documentsAddPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Importer des photos'**
  String get documentsAddPhotos;

  /// No description provided for @documentOpenedAt.
  ///
  /// In fr, this message translates to:
  /// **'Consulté {when}'**
  String documentOpenedAt(String when);

  /// No description provided for @documentAddedAt.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté {when}'**
  String documentAddedAt(String when);

  /// No description provided for @documentFavoriteAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter aux favoris'**
  String get documentFavoriteAdd;

  /// No description provided for @documentFavoriteRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer des favoris'**
  String get documentFavoriteRemove;

  /// No description provided for @documentThumbnailSemantics.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu de {title}'**
  String documentThumbnailSemantics(String title);

  /// No description provided for @detailOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir'**
  String get detailOpen;

  /// No description provided for @detailShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get detailShare;

  /// No description provided for @detailExport.
  ///
  /// In fr, this message translates to:
  /// **'Exporter'**
  String get detailExport;

  /// No description provided for @shareWarningTitle.
  ///
  /// In fr, this message translates to:
  /// **'Partager ce document ?'**
  String get shareWarningTitle;

  /// No description provided for @shareWarningBody.
  ///
  /// In fr, this message translates to:
  /// **'Le fichier partagé ne sera plus protégé par DocuSafe. Envoyez-le uniquement à une personne de confiance.'**
  String get shareWarningBody;

  /// No description provided for @exportWarningTitle.
  ///
  /// In fr, this message translates to:
  /// **'Exporter ce document ?'**
  String get exportWarningTitle;

  /// No description provided for @exportWarningBody.
  ///
  /// In fr, this message translates to:
  /// **'La copie enregistrée ne sera plus protégée par DocuSafe. Choisissez un emplacement sûr.'**
  String get exportWarningBody;

  /// No description provided for @exportDone.
  ///
  /// In fr, this message translates to:
  /// **'Copie enregistrée.'**
  String get exportDone;

  /// No description provided for @exportAllTitle.
  ///
  /// In fr, this message translates to:
  /// **'Exporter mes données'**
  String get exportAllTitle;

  /// No description provided for @exportAllSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Tous les documents, non chiffrés, dans un fichier ZIP'**
  String get exportAllSubtitle;

  /// No description provided for @exportAllWarningTitle.
  ///
  /// In fr, this message translates to:
  /// **'Exporter tous vos documents ?'**
  String get exportAllWarningTitle;

  /// No description provided for @exportAllWarningBody.
  ///
  /// In fr, this message translates to:
  /// **'Le fichier ZIP contiendra tous vos documents en clair : il ne sera plus protégé par DocuSafe. Rangez-le dans un endroit sûr et supprimez-le quand vous n\'en avez plus besoin.'**
  String get exportAllWarningBody;

  /// No description provided for @exportAllEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun document à exporter.'**
  String get exportAllEmpty;

  /// No description provided for @exportAllInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Préparation de l\'archive…'**
  String get exportAllInProgress;

  /// No description provided for @exportAllDone.
  ///
  /// In fr, this message translates to:
  /// **'Archive enregistrée.'**
  String get exportAllDone;

  /// No description provided for @exportUncategorized.
  ///
  /// In fr, this message translates to:
  /// **'Sans catégorie'**
  String get exportUncategorized;

  /// No description provided for @exportArchiveName.
  ///
  /// In fr, this message translates to:
  /// **'DocuSafe-export-{date}.zip'**
  String exportArchiveName(String date);

  /// No description provided for @exportTooLarge.
  ///
  /// In fr, this message translates to:
  /// **'Vos documents dépassent 200 Mo : l\'export en un seul fichier n\'est pas possible. Exportez-les un par un depuis leur fiche.'**
  String get exportTooLarge;

  /// No description provided for @detailEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get detailEdit;

  /// No description provided for @detailMove.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer'**
  String get detailMove;

  /// No description provided for @detailDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get detailDelete;

  /// No description provided for @detailExpiration.
  ///
  /// In fr, this message translates to:
  /// **'Expiration'**
  String get detailExpiration;

  /// No description provided for @detailIssue.
  ///
  /// In fr, this message translates to:
  /// **'Émission'**
  String get detailIssue;

  /// No description provided for @detailType.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get detailType;

  /// No description provided for @detailTags.
  ///
  /// In fr, this message translates to:
  /// **'Tags'**
  String get detailTags;

  /// No description provided for @detailAddedOn.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté le'**
  String get detailAddedOn;

  /// No description provided for @detailDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get detailDescription;

  /// No description provided for @detailFile.
  ///
  /// In fr, this message translates to:
  /// **'Fichier'**
  String get detailFile;

  /// No description provided for @detailIntegrity.
  ///
  /// In fr, this message translates to:
  /// **'Chiffré · intégrité vérifiée'**
  String get detailIntegrity;

  /// No description provided for @detailMoveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer vers'**
  String get detailMoveTitle;

  /// No description provided for @detailNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Ce document n\'existe plus.'**
  String get detailNotFound;

  /// No description provided for @viewerCorruptTitle.
  ///
  /// In fr, this message translates to:
  /// **'Document illisible'**
  String get viewerCorruptTitle;

  /// No description provided for @viewerCorruptBody.
  ///
  /// In fr, this message translates to:
  /// **'Ce fichier a été modifié ou endommagé en dehors de DocuSafe. Par sécurité, il n\'est pas affiché.'**
  String get viewerCorruptBody;

  /// No description provided for @viewerMissingBody.
  ///
  /// In fr, this message translates to:
  /// **'Le fichier de ce document est introuvable sur le téléphone.'**
  String get viewerMissingBody;

  /// No description provided for @viewerDeleteEntry.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la fiche'**
  String get viewerDeleteEntry;

  /// No description provided for @viewerPage.
  ///
  /// In fr, this message translates to:
  /// **'{current} / {total}'**
  String viewerPage(int current, int total);

  /// No description provided for @viewerOpening.
  ///
  /// In fr, this message translates to:
  /// **'Déchiffrement…'**
  String get viewerOpening;

  /// No description provided for @editTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get editTitle;

  /// No description provided for @editName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get editName;

  /// No description provided for @editCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get editCategory;

  /// No description provided for @editDocType.
  ///
  /// In fr, this message translates to:
  /// **'Type de document'**
  String get editDocType;

  /// No description provided for @editDocTypeHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : passeport, facture'**
  String get editDocTypeHint;

  /// No description provided for @editIssueDate.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'émission'**
  String get editIssueDate;

  /// No description provided for @editExpirationDate.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'expiration'**
  String get editExpirationDate;

  /// No description provided for @editTags.
  ///
  /// In fr, this message translates to:
  /// **'Tags'**
  String get editTags;

  /// No description provided for @editTagsHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter…'**
  String get editTagsHint;

  /// No description provided for @editDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get editDescription;

  /// No description provided for @editOptional.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif'**
  String get editOptional;

  /// No description provided for @editNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Donnez un nom au document.'**
  String get editNameRequired;

  /// No description provided for @editClearDate.
  ///
  /// In fr, this message translates to:
  /// **'Effacer la date'**
  String get editClearDate;

  /// No description provided for @editSaved.
  ///
  /// In fr, this message translates to:
  /// **'Modifications enregistrées.'**
  String get editSaved;

  /// No description provided for @deleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get deleteTitle;

  /// No description provided for @deleteQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce document ?'**
  String get deleteQuestion;

  /// No description provided for @deleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est définitive. Le document sera effacé de votre coffre et ne pourra pas être récupéré.'**
  String get deleteBody;

  /// No description provided for @deleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement'**
  String get deleteConfirm;

  /// No description provided for @deleteDone.
  ///
  /// In fr, this message translates to:
  /// **'Document supprimé.'**
  String get deleteDone;

  /// No description provided for @importTitle.
  ///
  /// In fr, this message translates to:
  /// **'Importer'**
  String get importTitle;

  /// No description provided for @importSourceFiles.
  ///
  /// In fr, this message translates to:
  /// **'Fichiers'**
  String get importSourceFiles;

  /// No description provided for @importSourceFilesSub.
  ///
  /// In fr, this message translates to:
  /// **'PDF et images'**
  String get importSourceFilesSub;

  /// No description provided for @importSourceGallery.
  ///
  /// In fr, this message translates to:
  /// **'Galerie'**
  String get importSourceGallery;

  /// No description provided for @importSourceGallerySub.
  ///
  /// In fr, this message translates to:
  /// **'Photos'**
  String get importSourceGallerySub;

  /// No description provided for @importSelected.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 fichier sélectionné} other{{count} fichiers sélectionnés}}'**
  String importSelected(int count);

  /// No description provided for @importChecking.
  ///
  /// In fr, this message translates to:
  /// **'Vérification…'**
  String get importChecking;

  /// No description provided for @importDuplicate.
  ///
  /// In fr, this message translates to:
  /// **'Déjà dans votre coffre'**
  String get importDuplicate;

  /// No description provided for @importUnsupported.
  ///
  /// In fr, this message translates to:
  /// **'Format non pris en charge'**
  String get importUnsupported;

  /// No description provided for @importTooLarge.
  ///
  /// In fr, this message translates to:
  /// **'Fichier trop volumineux (100 Mo maximum)'**
  String get importTooLarge;

  /// No description provided for @importUnreadable.
  ///
  /// In fr, this message translates to:
  /// **'Fichier illisible'**
  String get importUnreadable;

  /// No description provided for @importEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Fichier vide'**
  String get importEmpty;

  /// No description provided for @importFormats.
  ///
  /// In fr, this message translates to:
  /// **'Formats acceptés : PDF, JPEG et PNG.'**
  String get importFormats;

  /// No description provided for @importContinue.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Continuer} =1{Continuer avec 1 fichier} other{Continuer avec {count} fichiers}}'**
  String importContinue(int count);

  /// No description provided for @importIncludeDuplicate.
  ///
  /// In fr, this message translates to:
  /// **'Importer quand même'**
  String get importIncludeDuplicate;

  /// No description provided for @importInfoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Informations'**
  String get importInfoTitle;

  /// No description provided for @importWillBeEncrypted.
  ///
  /// In fr, this message translates to:
  /// **'Sera chiffré à l\'enregistrement'**
  String get importWillBeEncrypted;

  /// No description provided for @importCommonCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie commune aux {count} fichiers, modifiable ensuite.'**
  String importCommonCategory(int count);

  /// No description provided for @importSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer dans le coffre'**
  String get importSave;

  /// No description provided for @importSaving.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement…'**
  String get importSaving;

  /// No description provided for @importStageEncrypting.
  ///
  /// In fr, this message translates to:
  /// **'Chiffrement'**
  String get importStageEncrypting;

  /// No description provided for @importStageVerifying.
  ///
  /// In fr, this message translates to:
  /// **'Vérification'**
  String get importStageVerifying;

  /// No description provided for @importStageThumbnail.
  ///
  /// In fr, this message translates to:
  /// **'Miniature'**
  String get importStageThumbnail;

  /// No description provided for @importStageSaving.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement'**
  String get importStageSaving;

  /// No description provided for @importStageCleaning.
  ///
  /// In fr, this message translates to:
  /// **'Nettoyage'**
  String get importStageCleaning;

  /// No description provided for @importDontClose.
  ///
  /// In fr, this message translates to:
  /// **'Ne fermez pas l\'application.'**
  String get importDontClose;

  /// No description provided for @importProgress.
  ///
  /// In fr, this message translates to:
  /// **'Fichier {current} sur {total}'**
  String importProgress(int current, int total);

  /// No description provided for @importDone.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 document enregistré.} other{{count} documents enregistrés.}}'**
  String importDone(int count);

  /// No description provided for @importOriginalReminder.
  ///
  /// In fr, this message translates to:
  /// **'L\'original se trouve toujours dans votre galerie ou vos fichiers. Supprimez-le si vous voulez le garder uniquement dans DocuSafe.'**
  String get importOriginalReminder;

  /// No description provided for @importFailed.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 fichier n\'a pas pu être enregistré.} other{{count} fichiers n\'ont pas pu être enregistrés.}}'**
  String importFailed(int count);

  /// No description provided for @importNothingSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun fichier sélectionné.'**
  String get importNothingSelected;

  /// No description provided for @categoriesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get categoriesTitle;

  /// No description provided for @categoriesNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle catégorie'**
  String get categoriesNew;

  /// No description provided for @categoriesDefault.
  ///
  /// In fr, this message translates to:
  /// **'par défaut'**
  String get categoriesDefault;

  /// No description provided for @categoryEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get categoryEditTitle;

  /// No description provided for @categoryNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle catégorie'**
  String get categoryNewTitle;

  /// No description provided for @categoryName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get categoryName;

  /// No description provided for @categoryNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Donnez un nom à la catégorie.'**
  String get categoryNameRequired;

  /// No description provided for @categoryNameDuplicate.
  ///
  /// In fr, this message translates to:
  /// **'Une catégorie porte déjà ce nom.'**
  String get categoryNameDuplicate;

  /// No description provided for @categoryIcon.
  ///
  /// In fr, this message translates to:
  /// **'Icône'**
  String get categoryIcon;

  /// No description provided for @categoryColor.
  ///
  /// In fr, this message translates to:
  /// **'Couleur'**
  String get categoryColor;

  /// No description provided for @categoryDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la catégorie'**
  String get categoryDelete;

  /// No description provided for @categoryDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer « {name} » ?'**
  String categoryDeleteTitle(String name);

  /// No description provided for @categoryDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Elle ne contient aucun document.} =1{Son document ne sera pas supprimé. Choisissez où le déplacer.} other{Ses {count} documents ne seront pas supprimés. Choisissez où les déplacer.}}'**
  String categoryDeleteBody(int count);

  /// No description provided for @categoryMoveTo.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer vers'**
  String get categoryMoveTo;

  /// No description provided for @categoryDeleteAction.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer et supprimer'**
  String get categoryDeleteAction;

  /// No description provided for @categoryDeleteOnlyAction.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get categoryDeleteOnlyAction;

  /// No description provided for @categorySaved.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie enregistrée.'**
  String get categorySaved;

  /// No description provided for @categoryDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie supprimée.'**
  String get categoryDeleted;

  /// No description provided for @categoryColorName.
  ///
  /// In fr, this message translates to:
  /// **'Couleur {name}'**
  String categoryColorName(String name);

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settingsTitle;

  /// No description provided for @settingsCategories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get settingsCategories;

  /// No description provided for @settingsPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité'**
  String get settingsPrivacy;

  /// No description provided for @settingsTerms.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get settingsTerms;

  /// No description provided for @settingsAbout.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get settingsAbout;

  /// No description provided for @settingsAboutVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version {version}'**
  String settingsAboutVersion(String version);

  /// No description provided for @settingsLicenses.
  ///
  /// In fr, this message translates to:
  /// **'Licences des composants'**
  String get settingsLicenses;

  /// No description provided for @scanTitle.
  ///
  /// In fr, this message translates to:
  /// **'Scanner'**
  String get scanTitle;

  /// No description provided for @scanHeadline.
  ///
  /// In fr, this message translates to:
  /// **'Numériser un document'**
  String get scanHeadline;

  /// No description provided for @scanBody.
  ///
  /// In fr, this message translates to:
  /// **'Les contours sont détectés automatiquement. Vous pourrez recadrer et ajouter plusieurs pages.'**
  String get scanBody;

  /// No description provided for @scanStart.
  ///
  /// In fr, this message translates to:
  /// **'Numériser'**
  String get scanStart;

  /// No description provided for @scanImportPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Importer des photos'**
  String get scanImportPhotos;

  /// No description provided for @scanTipsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pour un bon résultat'**
  String get scanTipsTitle;

  /// No description provided for @scanTipLight.
  ///
  /// In fr, this message translates to:
  /// **'Bonne lumière, sans reflet'**
  String get scanTipLight;

  /// No description provided for @scanTipFlat.
  ///
  /// In fr, this message translates to:
  /// **'Document bien à plat'**
  String get scanTipFlat;

  /// No description provided for @scanTipContrast.
  ///
  /// In fr, this message translates to:
  /// **'Fond d\'une couleur différente'**
  String get scanTipContrast;

  /// No description provided for @scanFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le scanner n\'a pas pu s\'ouvrir. Vérifiez que DocuSafe a accès à l\'appareil photo dans les réglages du téléphone.'**
  String get scanFailed;

  /// No description provided for @scanPreviewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu du scan'**
  String get scanPreviewTitle;

  /// No description provided for @scanPreviewHint.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 page.} other{{count} pages. Maintenez une page pour la déplacer.}}'**
  String scanPreviewHint(int count);

  /// No description provided for @scanPageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Page {number}'**
  String scanPageLabel(int number);

  /// No description provided for @scanRemovePage.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la page {number}'**
  String scanRemovePage(int number);

  /// No description provided for @scanAddPages.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des pages'**
  String get scanAddPages;

  /// No description provided for @scanRestart.
  ///
  /// In fr, this message translates to:
  /// **'Recommencer'**
  String get scanRestart;

  /// No description provided for @scanContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get scanContinue;

  /// No description provided for @scanBuilding.
  ///
  /// In fr, this message translates to:
  /// **'Création du PDF…'**
  String get scanBuilding;

  /// No description provided for @scanDiscardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner ce scan ?'**
  String get scanDiscardTitle;

  /// No description provided for @scanDiscardBody.
  ///
  /// In fr, this message translates to:
  /// **'Les pages numérisées seront effacées.'**
  String get scanDiscardBody;

  /// No description provided for @scanDiscard.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner'**
  String get scanDiscard;

  /// No description provided for @scanDefaultTitle.
  ///
  /// In fr, this message translates to:
  /// **'Scan du {date}'**
  String scanDefaultTitle(String date);

  /// No description provided for @documentsAddScan.
  ///
  /// In fr, this message translates to:
  /// **'Scanner un document'**
  String get documentsAddScan;

  /// No description provided for @homeScan.
  ///
  /// In fr, this message translates to:
  /// **'Scanner'**
  String get homeScan;

  /// No description provided for @homeScanDocument.
  ///
  /// In fr, this message translates to:
  /// **'Scanner un document'**
  String get homeScanDocument;

  /// No description provided for @homeEmptyBodyFinal.
  ///
  /// In fr, this message translates to:
  /// **'Numérisez ou importez votre premier document. Il sera chiffré sur ce téléphone.'**
  String get homeEmptyBodyFinal;

  /// No description provided for @homeSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un document'**
  String get homeSearchHint;

  /// No description provided for @searchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un document'**
  String get searchHint;

  /// No description provided for @searchClear.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get searchClear;

  /// No description provided for @searchResults.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 résultat} other{{count} résultats}}'**
  String searchResults(int count);

  /// No description provided for @searchNoResultTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get searchNoResultTitle;

  /// No description provided for @searchNoResultBody.
  ///
  /// In fr, this message translates to:
  /// **'Essayez un autre mot ou retirez un filtre.'**
  String get searchNoResultBody;

  /// No description provided for @searchClearFilters.
  ///
  /// In fr, this message translates to:
  /// **'Effacer les filtres'**
  String get searchClearFilters;

  /// No description provided for @searchStartTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher dans le coffre'**
  String get searchStartTitle;

  /// No description provided for @searchStartBody.
  ///
  /// In fr, this message translates to:
  /// **'Nom, type, description, tags ou nom du fichier. Majuscules et accents sont ignorés.'**
  String get searchStartBody;

  /// No description provided for @searchFilterCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get searchFilterCategory;

  /// No description provided for @searchFilterTag.
  ///
  /// In fr, this message translates to:
  /// **'Tag'**
  String get searchFilterTag;

  /// No description provided for @searchFilterFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Favoris'**
  String get searchFilterFavorites;

  /// No description provided for @searchFilterFormat.
  ///
  /// In fr, this message translates to:
  /// **'Format'**
  String get searchFilterFormat;

  /// No description provided for @searchFilterAdded.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté'**
  String get searchFilterAdded;

  /// No description provided for @searchFilterExpiry.
  ///
  /// In fr, this message translates to:
  /// **'Expiration'**
  String get searchFilterExpiry;

  /// No description provided for @searchAddedWeek.
  ///
  /// In fr, this message translates to:
  /// **'7 derniers jours'**
  String get searchAddedWeek;

  /// No description provided for @searchAddedMonth.
  ///
  /// In fr, this message translates to:
  /// **'30 derniers jours'**
  String get searchAddedMonth;

  /// No description provided for @searchAddedYear.
  ///
  /// In fr, this message translates to:
  /// **'12 derniers mois'**
  String get searchAddedYear;

  /// No description provided for @searchExpiryExpired.
  ///
  /// In fr, this message translates to:
  /// **'Expirés'**
  String get searchExpiryExpired;

  /// No description provided for @searchExpiry30.
  ///
  /// In fr, this message translates to:
  /// **'Dans les 30 jours'**
  String get searchExpiry30;

  /// No description provided for @searchExpiry365.
  ///
  /// In fr, this message translates to:
  /// **'Dans l\'année'**
  String get searchExpiry365;

  /// No description provided for @searchExpiryNone.
  ///
  /// In fr, this message translates to:
  /// **'Sans date'**
  String get searchExpiryNone;

  /// No description provided for @searchAny.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get searchAny;

  /// No description provided for @searchNoTags.
  ///
  /// In fr, this message translates to:
  /// **'Aucun tag pour l\'instant.'**
  String get searchNoTags;

  /// No description provided for @searchMatchTag.
  ///
  /// In fr, this message translates to:
  /// **'Tag : {tags}'**
  String searchMatchTag(String tags);

  /// No description provided for @notificationTitle.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =0{Échéance aujourd\'hui} =1{Échéance demain} other{Échéance dans {days} jours}}'**
  String notificationTitle(int days);

  /// No description provided for @notificationTitleNamed.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =0{{title} expire aujourd\'hui} =1{{title} expire demain} other{{title} expire dans {days} jours}}'**
  String notificationTitleNamed(String title, int days);

  /// No description provided for @notificationBody.
  ///
  /// In fr, this message translates to:
  /// **'Un document de votre coffre arrive à échéance.'**
  String get notificationBody;

  /// No description provided for @navDeadlinesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Échéances'**
  String get navDeadlinesTitle;

  /// No description provided for @deadlinesAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get deadlinesAll;

  /// No description provided for @deadlinesExpiredCount.
  ///
  /// In fr, this message translates to:
  /// **'Expirés · {count}'**
  String deadlinesExpiredCount(int count);

  /// No description provided for @deadlinesSoonCount.
  ///
  /// In fr, this message translates to:
  /// **'30 jours · {count}'**
  String deadlinesSoonCount(int count);

  /// No description provided for @deadlinesGroupExpired.
  ///
  /// In fr, this message translates to:
  /// **'Expirés'**
  String get deadlinesGroupExpired;

  /// No description provided for @deadlinesGroupSoon.
  ///
  /// In fr, this message translates to:
  /// **'Dans les 30 jours'**
  String get deadlinesGroupSoon;

  /// No description provided for @deadlinesGroupLater.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get deadlinesGroupLater;

  /// No description provided for @deadlinesExpiredSince.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =0{Aujourd\'hui} other{Depuis {days} j}}'**
  String deadlinesExpiredSince(int days);

  /// No description provided for @deadlinesEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune échéance'**
  String get deadlinesEmptyTitle;

  /// No description provided for @deadlinesEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez une date d\'expiration à un document pour être prévenu à temps.'**
  String get deadlinesEmptyBody;

  /// No description provided for @deadlinesNotificationsOff.
  ///
  /// In fr, this message translates to:
  /// **'Les rappels sont désactivés. Les échéances restent visibles ici.'**
  String get deadlinesNotificationsOff;

  /// No description provided for @homeUpcomingDeadlines.
  ///
  /// In fr, this message translates to:
  /// **'Échéances à venir'**
  String get homeUpcomingDeadlines;

  /// No description provided for @remindersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rappels'**
  String get remindersTitle;

  /// No description provided for @remindersSection.
  ///
  /// In fr, this message translates to:
  /// **'Rappels'**
  String get remindersSection;

  /// No description provided for @remindersOffset.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =0{Le jour même} =1{1 jour avant} other{{days} jours avant}}'**
  String remindersOffset(int days);

  /// No description provided for @remindersPast.
  ///
  /// In fr, this message translates to:
  /// **'{date} · passé'**
  String remindersPast(String date);

  /// No description provided for @remindersAt.
  ///
  /// In fr, this message translates to:
  /// **'{date}, vers {time}'**
  String remindersAt(String date, String time);

  /// No description provided for @remindersAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un rappel'**
  String get remindersAdd;

  /// No description provided for @remindersAddTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau rappel'**
  String get remindersAddTitle;

  /// No description provided for @remindersAddLabel.
  ///
  /// In fr, this message translates to:
  /// **'Jours avant l\'expiration'**
  String get remindersAddLabel;

  /// No description provided for @remindersAddInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un nombre de jours entre 0 et 3650.'**
  String get remindersAddInvalid;

  /// No description provided for @remindersDiscretion.
  ///
  /// In fr, this message translates to:
  /// **'Par discrétion, la notification n\'affiche pas le nom du document.'**
  String get remindersDiscretion;

  /// No description provided for @remindersNoDate.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez une date d\'expiration pour programmer des rappels.'**
  String get remindersNoDate;

  /// No description provided for @remindersDisabledGlobally.
  ///
  /// In fr, this message translates to:
  /// **'Les rappels sont désactivés dans les paramètres.'**
  String get remindersDisabledGlobally;

  /// No description provided for @permissionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Être prévenu avant l\'expiration ?'**
  String get permissionTitle;

  /// No description provided for @permissionBody.
  ///
  /// In fr, this message translates to:
  /// **'DocuSafe vous rappelle l\'échéance 90, 30 et 7 jours avant, puis le jour même. Les rappels restent sur votre téléphone.'**
  String get permissionBody;

  /// No description provided for @permissionAllow.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser les notifications'**
  String get permissionAllow;

  /// No description provided for @settingsNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @notifSettingsEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Rappels d\'échéance'**
  String get notifSettingsEnabled;

  /// No description provided for @notifSettingsEnabledSub.
  ///
  /// In fr, this message translates to:
  /// **'Notifications locales, sans Internet'**
  String get notifSettingsEnabledSub;

  /// No description provided for @notifSettingsDefaults.
  ///
  /// In fr, this message translates to:
  /// **'Rappels par défaut'**
  String get notifSettingsDefaults;

  /// No description provided for @notifSettingsDefaultsHint.
  ///
  /// In fr, this message translates to:
  /// **'Pour les nouvelles dates d\'expiration.'**
  String get notifSettingsDefaultsHint;

  /// No description provided for @notifSettingsAddOffset.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get notifSettingsAddOffset;

  /// No description provided for @notifSettingsTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure d\'envoi'**
  String get notifSettingsTime;

  /// No description provided for @notifSettingsShowTitle.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le nom du document'**
  String get notifSettingsShowTitle;

  /// No description provided for @notifSettingsShowTitleOff.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé : le nom n\'apparaît pas sur l\'écran verrouillé'**
  String get notifSettingsShowTitleOff;

  /// No description provided for @notifSettingsShowTitleOn.
  ///
  /// In fr, this message translates to:
  /// **'Activé : le nom apparaît sur l\'écran verrouillé'**
  String get notifSettingsShowTitleOn;

  /// No description provided for @notifSettingsPreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get notifSettingsPreview;

  /// No description provided for @notifSettingsPreviewNow.
  ///
  /// In fr, this message translates to:
  /// **'DocuSafe · maintenant'**
  String get notifSettingsPreviewNow;

  /// No description provided for @notifSettingsExampleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Passeport'**
  String get notifSettingsExampleTitle;

  /// No description provided for @offsetChip.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =0{Le jour même} =1{1 jour} other{{days} jours}}'**
  String offsetChip(int days);

  /// No description provided for @errorStorage.
  ///
  /// In fr, this message translates to:
  /// **'Le stockage du téléphone n\'a pas répondu. Vérifiez l\'espace disponible et réessayez.'**
  String get errorStorage;

  /// No description provided for @errorIntegrity.
  ///
  /// In fr, this message translates to:
  /// **'Le fichier a été modifié ou est illisible. Il n\'a pas été affiché.'**
  String get errorIntegrity;

  /// No description provided for @errorBiometricUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'L\'empreinte n\'est pas disponible pour le moment. Utilisez votre code.'**
  String get errorBiometricUnavailable;

  /// No description provided for @errorVaultLocked.
  ///
  /// In fr, this message translates to:
  /// **'Le coffre est verrouillé. Déverrouillez-le pour continuer.'**
  String get errorVaultLocked;

  /// No description provided for @errorScanner.
  ///
  /// In fr, this message translates to:
  /// **'Le scanner n\'a pas pu s\'ouvrir. Vérifiez l\'accès à l\'appareil photo dans les réglages du téléphone.'**
  String get errorScanner;

  /// No description provided for @errorUnexpected.
  ///
  /// In fr, this message translates to:
  /// **'Quelque chose n\'a pas fonctionné. Réessayez dans un instant.'**
  String get errorUnexpected;
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
      <String>['fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
