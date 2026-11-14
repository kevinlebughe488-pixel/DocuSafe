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
