// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'DocuSafe';

  @override
  String get appTagline => 'Vos documents, protégés.';

  @override
  String get secureLabel => 'Chiffré sur cet appareil';

  @override
  String get secureLabelPlural => 'Chiffrés sur cet appareil';

  @override
  String get commonNext => 'Suivant';

  @override
  String get commonSkip => 'Passer';

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonLater => 'Plus tard';

  @override
  String get commonCopy => 'Copier';

  @override
  String get commonCopied =>
      'Copié. Le presse-papiers sera vidé dans une minute.';

  @override
  String get commonBack => 'Retour';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonConfirm => 'Confirmer';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonDone => 'Terminé';

  @override
  String get commonErrorTitle => 'Une erreur est survenue';

  @override
  String get commonErrorBody =>
      'L\'opération n\'a pas pu aboutir. Réessayez dans un instant.';

  @override
  String get onboardingTitle1 => 'Bienvenue dans DocuSafe';

  @override
  String get onboardingBody1 =>
      'Le coffre-fort de vos documents importants : pièces d\'identité, diplômes, contrats, factures.';

  @override
  String get onboardingTitle2 => 'Tout reste sur votre téléphone';

  @override
  String get onboardingBody2 =>
      'Pas de compte à créer, pas de serveur. DocuSafe fonctionne sans connexion Internet.';

  @override
  String get onboardingTitle3 => 'Chiffré et protégé par votre code';

  @override
  String get onboardingBody3 =>
      'Chaque document est chiffré. Sans votre code ou votre empreinte, personne ne peut le lire.';

  @override
  String get onboardingTitle4 => 'Vos documents vous appartiennent';

  @override
  String get onboardingBody4 =>
      'Aucune publicité, aucun suivi. Rien ne quitte votre téléphone sans votre accord.';

  @override
  String get onboardingPrivacyLink => 'Politique de confidentialité';

  @override
  String get onboardingTermsLink => 'Conditions d\'utilisation';

  @override
  String get onboardingCreateVault => 'Créer mon coffre-fort';

  @override
  String onboardingPageLabel(int current, int total) {
    return 'Page $current sur $total';
  }

  @override
  String setupStep(int step, int total) {
    return 'Étape $step sur $total';
  }

  @override
  String get setupPinTitle => 'Choisissez votre code';

  @override
  String get setupPinBody =>
      '6 chiffres ou plus. Ce code protège tous vos documents.';

  @override
  String get setupPinHint => 'Évitez les suites simples comme 123456.';

  @override
  String get setupPinConfirmTitle => 'Confirmez votre code';

  @override
  String get setupPinConfirmBody => 'Saisissez le même code une seconde fois.';

  @override
  String get setupPinTooSimple =>
      'Ce code est trop simple. Choisissez-en un autre.';

  @override
  String get setupPinTooShort => 'Le code doit avoir au moins 6 chiffres.';

  @override
  String get setupPinMismatch =>
      'Les deux codes ne sont pas identiques. Recommencez.';

  @override
  String get setupPreparing => 'Préparation de votre coffre…';

  @override
  String get setupRecoveryTitle => 'Votre clé de récupération';

  @override
  String get setupRecoveryBody =>
      'Elle permet de retrouver l\'accès si vous oubliez votre code. Notez-la et gardez-la ailleurs que sur ce téléphone.';

  @override
  String get setupRecoveryWarning =>
      'Sans votre code et sans cette clé, vos documents seront définitivement perdus. Personne ne pourra les récupérer.';

  @override
  String get setupRecoveryChecked => 'J\'ai conservé ma clé en lieu sûr';

  @override
  String setupRecoveryKeySemantics(String key) {
    return 'Clé de récupération : $key';
  }

  @override
  String get setupBiometricTitle => 'Déverrouiller plus vite ?';

  @override
  String get setupBiometricBody =>
      'Utilisez votre empreinte pour ouvrir DocuSafe. Votre code reste toujours valable.';

  @override
  String get setupBiometricBodyFace =>
      'Utilisez votre visage pour ouvrir DocuSafe. Votre code reste toujours valable.';

  @override
  String get setupBiometricEnable => 'Activer l\'empreinte';

  @override
  String get setupBiometricEnableFace => 'Activer la reconnaissance du visage';

  @override
  String get setupBiometricFailed =>
      'L\'empreinte n\'a pas pu être activée. Vous pourrez réessayer dans les paramètres.';

  @override
  String get unlockTitle => 'Saisissez votre code';

  @override
  String get unlockBiometricReason => 'Déverrouiller DocuSafe';

  @override
  String unlockWrongPin(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: 'Il reste $remaining essais.',
      one: 'Il reste 1 essai.',
      zero: 'Dernier essai avant une attente.',
    );
    return 'Code incorrect. $_temp0';
  }

  @override
  String get unlockTooManyTitle => 'Trop d\'essais';

  @override
  String get unlockTooManyBody => 'Par sécurité, patientez avant de réessayer.';

  @override
  String unlockRetryIn(String delay) {
    return 'Réessayez dans $delay';
  }

  @override
  String get unlockForgotPin => 'Code oublié ?';

  @override
  String get unlockUseRecoveryKey => 'Utiliser ma clé de récupération';

  @override
  String get unlockBiometricChanged =>
      'Votre biométrie a changé. Saisissez votre code.';

  @override
  String get unlockBiometricButton => 'Déverrouiller avec l\'empreinte';

  @override
  String get unlockSlotMissing =>
      'Le stockage sécurisé du téléphone est endommagé. Utilisez votre clé de récupération.';

  @override
  String get recoveryTitle => 'Code oublié';

  @override
  String get recoveryBody =>
      'Saisissez la clé de récupération affichée à la création de votre coffre.';

  @override
  String get recoveryFieldLabel => 'Clé de récupération';

  @override
  String recoveryCount(int count, int total) {
    return '$count caractères sur $total';
  }

  @override
  String get recoveryInfo =>
      'Vous choisirez ensuite un nouveau code. Vos documents ne changent pas.';

  @override
  String get recoveryVerify => 'Vérifier la clé';

  @override
  String get recoveryInvalid =>
      'Cette clé n\'est pas reconnue. Vérifiez chaque caractère.';

  @override
  String get recoveryNewPinTitle => 'Choisissez un nouveau code';

  @override
  String get recoveryNewPinBody =>
      '6 chiffres ou plus. Il remplace l\'ancien code.';

  @override
  String durationSeconds(int count) {
    return '$count s';
  }

  @override
  String durationMinutes(int count) {
    return '$count min';
  }

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String homeDocumentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents',
      one: '1 document',
      zero: 'Aucun document',
    );
    return '$_temp0';
  }

  @override
  String get homeLock => 'Verrouiller';

  @override
  String get homeSettings => 'Paramètres';

  @override
  String get homeEmptyTitle => 'Votre coffre est vide';

  @override
  String get homeEmptyBody =>
      'Le scanner et l\'importation arrivent à la prochaine étape du développement. Votre coffre est prêt : code, chiffrement et catégories sont en place.';

  @override
  String get homeCategories => 'Catégories';

  @override
  String homeCategoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents',
      one: '1 document',
      zero: 'Aucun document',
    );
    return '$_temp0';
  }

  @override
  String get settingsSecurityTitle => 'Sécurité';

  @override
  String get settingsChangePin => 'Changer le code';

  @override
  String get settingsBiometric => 'Empreinte digitale';

  @override
  String get settingsBiometricFace => 'Reconnaissance du visage';

  @override
  String get settingsBiometricSubtitle => 'Déverrouiller avec votre empreinte';

  @override
  String get settingsBiometricSubtitleFace => 'Déverrouiller avec votre visage';

  @override
  String get settingsBiometricUnavailable => 'Non disponible sur ce téléphone';

  @override
  String get settingsRecoveryKey => 'Clé de récupération';

  @override
  String get settingsRecoveryKeySubtitle => 'Créer une nouvelle clé';

  @override
  String get settingsRecoveryKeyNewTitle => 'Nouvelle clé de récupération';

  @override
  String get settingsRecoveryKeyNewBody =>
      'L\'ancienne clé ne fonctionne plus. Notez celle-ci et gardez-la ailleurs que sur ce téléphone.';

  @override
  String get settingsLockSection => 'Verrouillage';

  @override
  String get settingsAutoLock => 'Verrouillage automatique';

  @override
  String settingsAutoLockSubtitle(String delay) {
    return 'Après $delay sans action';
  }

  @override
  String get settingsAutoLockChoice => 'Délai de verrouillage';

  @override
  String get settingsScreenshots => 'Captures d\'écran';

  @override
  String get settingsScreenshotsSubtitle =>
      'Autoriser les captures et l\'aperçu des applications récentes';

  @override
  String get settingsLockNow => 'Verrouiller maintenant';

  @override
  String get settingsDangerSection => 'Zone sensible';

  @override
  String get settingsWipe => 'Effacer le coffre';

  @override
  String get settingsWipeSubtitle =>
      'Supprime définitivement tous les documents';

  @override
  String get settingsWipeTitle => 'Effacer le coffre ?';

  @override
  String get settingsWipeBody =>
      'Tous vos documents, catégories et réglages seront supprimés de ce téléphone. Cette action est définitive. Pour confirmer, écrivez EFFACER.';

  @override
  String get settingsWipeConfirmWord => 'EFFACER';

  @override
  String get settingsWipeFieldLabel => 'Écrivez EFFACER';

  @override
  String get settingsWipeAction => 'Effacer définitivement';

  @override
  String get settingsPinChanged => 'Votre code a été changé.';

  @override
  String get settingsBiometricEnabled => 'L\'empreinte est activée.';

  @override
  String get settingsBiometricDisabled => 'L\'empreinte est désactivée.';

  @override
  String get settingsBiometricEnableReason =>
      'Activer le déverrouillage par empreinte';

  @override
  String get changePinTitle => 'Nouveau code';

  @override
  String get changePinBody => '6 chiffres ou plus. Il remplace l\'ancien code.';

  @override
  String get reauthTitle => 'Confirmez votre identité';

  @override
  String get reauthBody => 'Saisissez votre code pour continuer.';

  @override
  String get reauthBiometricReason => 'Confirmer l\'opération';

  @override
  String get legalPrivacyTitle => 'Politique de confidentialité';

  @override
  String get legalTermsTitle => 'Conditions d\'utilisation';

  @override
  String get legalDraftNotice =>
      'Version provisoire. Ce texte sera relu avant la publication de l\'application.';

  @override
  String get errorStorage =>
      'Le stockage du téléphone n\'a pas répondu. Vérifiez l\'espace disponible et réessayez.';

  @override
  String get errorIntegrity =>
      'Le fichier a été modifié ou est illisible. Il n\'a pas été affiché.';

  @override
  String get errorBiometricUnavailable =>
      'L\'empreinte n\'est pas disponible pour le moment. Utilisez votre code.';

  @override
  String get errorVaultLocked =>
      'Le coffre est verrouillé. Déverrouillez-le pour continuer.';

  @override
  String get errorUnexpected =>
      'Quelque chose n\'a pas fonctionné. Réessayez dans un instant.';
}
