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
  String get homeRecoveryBanner =>
      'Votre clé de récupération n\'est pas encore notée. Sans elle, un code oublié signifie des documents perdus.';

  @override
  String get homeRecoveryAction => 'Noter ma clé';

  @override
  String get settingsRecoveryKeyTodo => 'À noter dès maintenant';

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
  String setupBiometricBody(String method) {
    return 'Utilisez $method pour ouvrir DocuSafe. Votre code reste toujours valable.';
  }

  @override
  String setupBiometricEnable(String method) {
    return 'Activer $method';
  }

  @override
  String get setupBiometricFailed =>
      'Le déverrouillage rapide n\'a pas pu être activé. Vous pourrez réessayer dans les paramètres.';

  @override
  String get biometricFingerprint => 'l\'empreinte';

  @override
  String get biometricFingerprintTitle => 'Empreinte digitale';

  @override
  String get biometricFace => 'la reconnaissance du visage';

  @override
  String get biometricFaceTitle => 'Reconnaissance du visage';

  @override
  String get biometricFaceId => 'Face ID';

  @override
  String get biometricTouchId => 'Touch ID';

  @override
  String get biometricGeneric => 'la biométrie';

  @override
  String get biometricGenericTitle => 'Déverrouillage biométrique';

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
  String unlockBiometricButton(String method) {
    return 'Déverrouiller avec $method';
  }

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
  String settingsBiometricSubtitle(String method) {
    return 'Déverrouiller avec $method';
  }

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
  String get settingsBiometricEnabled => 'Le déverrouillage rapide est activé.';

  @override
  String get settingsBiometricDisabled =>
      'Le déverrouillage rapide est désactivé.';

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
  String get dateToday => 'Aujourd\'hui';

  @override
  String get dateYesterday => 'Hier';

  @override
  String dateTodayAt(String time) {
    return 'Aujourd\'hui à $time';
  }

  @override
  String get expiryExpired => 'Expiré';

  @override
  String expiryInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'J-$days',
      zero: 'Aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String expiryInMonths(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months mois',
      one: '1 mois',
    );
    return '$_temp0';
  }

  @override
  String expiryInYears(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years ans',
      one: '1 an',
    );
    return '$_temp0';
  }

  @override
  String expiryInYearsMonths(int years, int months) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years ans',
      one: '1 an',
    );
    return '$_temp0 $months mois';
  }

  @override
  String expiresOn(String date) {
    return 'Expire le $date';
  }

  @override
  String expiredOn(String date) {
    return 'Expiré le $date';
  }

  @override
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get navHome => 'Accueil';

  @override
  String get navDocuments => 'Documents';

  @override
  String get navScanner => 'Scanner';

  @override
  String get navDeadlines => 'Échéances';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get homeImport => 'Importer un fichier';

  @override
  String get homeEmptyBodyLotA =>
      'Importez votre premier document. Il sera chiffré sur ce téléphone. Le scanner arrive à la prochaine étape du développement.';

  @override
  String get homeRecentlyAdded => 'Ajoutés récemment';

  @override
  String get homeFavorites => 'Favoris';

  @override
  String get homeSeeAll => 'Tout voir';

  @override
  String get homeManage => 'Gérer';

  @override
  String get documentsTitle => 'Documents';

  @override
  String get documentsTabAll => 'Tous';

  @override
  String get documentsTabFavorites => 'Favoris';

  @override
  String get documentsTabRecent => 'Récents';

  @override
  String get documentsAllCategories => 'Toutes';

  @override
  String get documentsSort => 'Trier';

  @override
  String get documentsSortNewest => 'Plus récents d\'abord';

  @override
  String get documentsSortOldest => 'Plus anciens d\'abord';

  @override
  String get documentsSortTitle => 'Par nom';

  @override
  String get documentsSortExpiration => 'Par date d\'expiration';

  @override
  String get documentsRecentAdded => 'Ajoutés';

  @override
  String get documentsRecentOpened => 'Consultés';

  @override
  String get documentsEmptyTitle => 'Aucun document pour l\'instant';

  @override
  String get documentsEmptyBody =>
      'Importez votre premier document. Il sera chiffré sur ce téléphone.';

  @override
  String get documentsEmptyFilteredTitle => 'Aucun document ici';

  @override
  String get documentsEmptyFilteredBody =>
      'Changez de catégorie ou retirez le filtre.';

  @override
  String get documentsFavoritesEmptyTitle => 'Aucun favori';

  @override
  String get documentsFavoritesEmptyBody =>
      'Touchez l\'étoile d\'un document pour le retrouver ici.';

  @override
  String get documentsRecentEmptyTitle => 'Rien de récent';

  @override
  String get documentsRecentEmptyBody =>
      'Les documents ajoutés ou consultés apparaîtront ici.';

  @override
  String get documentsAdd => 'Ajouter';

  @override
  String get documentsAddFile => 'Importer un fichier';

  @override
  String get documentsAddPhotos => 'Importer des photos';

  @override
  String documentOpenedAt(String when) {
    return 'Consulté $when';
  }

  @override
  String documentAddedAt(String when) {
    return 'Ajouté $when';
  }

  @override
  String get documentFavoriteAdd => 'Ajouter aux favoris';

  @override
  String get documentFavoriteRemove => 'Retirer des favoris';

  @override
  String documentThumbnailSemantics(String title) {
    return 'Aperçu de $title';
  }

  @override
  String get detailOpen => 'Ouvrir';

  @override
  String get detailEdit => 'Modifier';

  @override
  String get detailMove => 'Déplacer';

  @override
  String get detailDelete => 'Supprimer';

  @override
  String get detailExpiration => 'Expiration';

  @override
  String get detailIssue => 'Émission';

  @override
  String get detailType => 'Type';

  @override
  String get detailTags => 'Tags';

  @override
  String get detailAddedOn => 'Ajouté le';

  @override
  String get detailDescription => 'Description';

  @override
  String get detailFile => 'Fichier';

  @override
  String get detailIntegrity => 'Chiffré · intégrité vérifiée';

  @override
  String get detailMoveTitle => 'Déplacer vers';

  @override
  String get detailNotFound => 'Ce document n\'existe plus.';

  @override
  String get viewerCorruptTitle => 'Document illisible';

  @override
  String get viewerCorruptBody =>
      'Ce fichier a été modifié ou endommagé en dehors de DocuSafe. Par sécurité, il n\'est pas affiché.';

  @override
  String get viewerMissingBody =>
      'Le fichier de ce document est introuvable sur le téléphone.';

  @override
  String get viewerDeleteEntry => 'Supprimer la fiche';

  @override
  String viewerPage(int current, int total) {
    return '$current / $total';
  }

  @override
  String get viewerOpening => 'Déchiffrement…';

  @override
  String get editTitle => 'Modifier';

  @override
  String get editName => 'Nom';

  @override
  String get editCategory => 'Catégorie';

  @override
  String get editDocType => 'Type de document';

  @override
  String get editDocTypeHint => 'Ex. : passeport, facture';

  @override
  String get editIssueDate => 'Date d\'émission';

  @override
  String get editExpirationDate => 'Date d\'expiration';

  @override
  String get editTags => 'Tags';

  @override
  String get editTagsHint => 'Ajouter…';

  @override
  String get editDescription => 'Description';

  @override
  String get editOptional => 'Facultatif';

  @override
  String get editNameRequired => 'Donnez un nom au document.';

  @override
  String get editClearDate => 'Effacer la date';

  @override
  String get editSaved => 'Modifications enregistrées.';

  @override
  String get deleteTitle => 'Supprimer';

  @override
  String get deleteQuestion => 'Supprimer ce document ?';

  @override
  String get deleteBody =>
      'Cette action est définitive. Le document sera effacé de votre coffre et ne pourra pas être récupéré.';

  @override
  String get deleteConfirm => 'Supprimer définitivement';

  @override
  String get deleteDone => 'Document supprimé.';

  @override
  String get importTitle => 'Importer';

  @override
  String get importSourceFiles => 'Fichiers';

  @override
  String get importSourceFilesSub => 'PDF et images';

  @override
  String get importSourceGallery => 'Galerie';

  @override
  String get importSourceGallerySub => 'Photos';

  @override
  String importSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers sélectionnés',
      one: '1 fichier sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get importChecking => 'Vérification…';

  @override
  String get importDuplicate => 'Déjà dans votre coffre';

  @override
  String get importUnsupported => 'Format non pris en charge';

  @override
  String get importTooLarge => 'Fichier trop volumineux (100 Mo maximum)';

  @override
  String get importUnreadable => 'Fichier illisible';

  @override
  String get importEmpty => 'Fichier vide';

  @override
  String get importFormats => 'Formats acceptés : PDF, JPEG et PNG.';

  @override
  String importContinue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Continuer avec $count fichiers',
      one: 'Continuer avec 1 fichier',
      zero: 'Continuer',
    );
    return '$_temp0';
  }

  @override
  String get importIncludeDuplicate => 'Importer quand même';

  @override
  String get importInfoTitle => 'Informations';

  @override
  String get importWillBeEncrypted => 'Sera chiffré à l\'enregistrement';

  @override
  String importCommonCategory(int count) {
    return 'Catégorie commune aux $count fichiers, modifiable ensuite.';
  }

  @override
  String get importSave => 'Enregistrer dans le coffre';

  @override
  String get importSaving => 'Enregistrement…';

  @override
  String get importStageEncrypting => 'Chiffrement';

  @override
  String get importStageVerifying => 'Vérification';

  @override
  String get importStageThumbnail => 'Miniature';

  @override
  String get importStageSaving => 'Enregistrement';

  @override
  String get importStageCleaning => 'Nettoyage';

  @override
  String get importDontClose => 'Ne fermez pas l\'application.';

  @override
  String importProgress(int current, int total) {
    return 'Fichier $current sur $total';
  }

  @override
  String importDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents enregistrés.',
      one: '1 document enregistré.',
    );
    return '$_temp0';
  }

  @override
  String get importOriginalReminder =>
      'L\'original se trouve toujours dans votre galerie ou vos fichiers. Supprimez-le si vous voulez le garder uniquement dans DocuSafe.';

  @override
  String importFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers n\'ont pas pu être enregistrés.',
      one: '1 fichier n\'a pas pu être enregistré.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingSelected => 'Aucun fichier sélectionné.';

  @override
  String get categoriesTitle => 'Catégories';

  @override
  String get categoriesNew => 'Nouvelle catégorie';

  @override
  String get categoriesDefault => 'par défaut';

  @override
  String get categoryEditTitle => 'Modifier';

  @override
  String get categoryNewTitle => 'Nouvelle catégorie';

  @override
  String get categoryName => 'Nom';

  @override
  String get categoryNameRequired => 'Donnez un nom à la catégorie.';

  @override
  String get categoryNameDuplicate => 'Une catégorie porte déjà ce nom.';

  @override
  String get categoryIcon => 'Icône';

  @override
  String get categoryColor => 'Couleur';

  @override
  String get categoryDelete => 'Supprimer la catégorie';

  @override
  String categoryDeleteTitle(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String categoryDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Ses $count documents ne seront pas supprimés. Choisissez où les déplacer.',
      one: 'Son document ne sera pas supprimé. Choisissez où le déplacer.',
      zero: 'Elle ne contient aucun document.',
    );
    return '$_temp0';
  }

  @override
  String get categoryMoveTo => 'Déplacer vers';

  @override
  String get categoryDeleteAction => 'Déplacer et supprimer';

  @override
  String get categoryDeleteOnlyAction => 'Supprimer';

  @override
  String get categorySaved => 'Catégorie enregistrée.';

  @override
  String get categoryDeleted => 'Catégorie supprimée.';

  @override
  String categoryColorName(String name) {
    return 'Couleur $name';
  }

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsCategories => 'Catégories';

  @override
  String get settingsPrivacy => 'Confidentialité';

  @override
  String get settingsTerms => 'Conditions d\'utilisation';

  @override
  String get settingsAbout => 'À propos';

  @override
  String settingsAboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsLicenses => 'Licences des composants';

  @override
  String get scanTitle => 'Scanner';

  @override
  String get scanHeadline => 'Numériser un document';

  @override
  String get scanBody =>
      'Les contours sont détectés automatiquement. Vous pourrez recadrer et ajouter plusieurs pages.';

  @override
  String get scanStart => 'Numériser';

  @override
  String get scanImportPhotos => 'Importer des photos';

  @override
  String get scanTipsTitle => 'Pour un bon résultat';

  @override
  String get scanTipLight => 'Bonne lumière, sans reflet';

  @override
  String get scanTipFlat => 'Document bien à plat';

  @override
  String get scanTipContrast => 'Fond d\'une couleur différente';

  @override
  String get scanFailed =>
      'Le scanner n\'a pas pu s\'ouvrir. Vérifiez que DocuSafe a accès à l\'appareil photo dans les réglages du téléphone.';

  @override
  String get scanPreviewTitle => 'Aperçu du scan';

  @override
  String scanPreviewHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages. Maintenez une page pour la déplacer.',
      one: '1 page.',
    );
    return '$_temp0';
  }

  @override
  String scanPageLabel(int number) {
    return 'Page $number';
  }

  @override
  String scanRemovePage(int number) {
    return 'Retirer la page $number';
  }

  @override
  String get scanAddPages => 'Ajouter des pages';

  @override
  String get scanRestart => 'Recommencer';

  @override
  String get scanContinue => 'Continuer';

  @override
  String get scanBuilding => 'Création du PDF…';

  @override
  String get scanDiscardTitle => 'Abandonner ce scan ?';

  @override
  String get scanDiscardBody => 'Les pages numérisées seront effacées.';

  @override
  String get scanDiscard => 'Abandonner';

  @override
  String scanDefaultTitle(String date) {
    return 'Scan du $date';
  }

  @override
  String get documentsAddScan => 'Scanner un document';

  @override
  String get homeScan => 'Scanner';

  @override
  String get homeScanDocument => 'Scanner un document';

  @override
  String get homeEmptyBodyFinal =>
      'Numérisez ou importez votre premier document. Il sera chiffré sur ce téléphone.';

  @override
  String get homeSearchHint => 'Rechercher un document';

  @override
  String get searchHint => 'Rechercher un document';

  @override
  String get searchClear => 'Effacer';

  @override
  String searchResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count résultats',
      one: '1 résultat',
    );
    return '$_temp0';
  }

  @override
  String get searchNoResultTitle => 'Aucun résultat';

  @override
  String get searchNoResultBody => 'Essayez un autre mot ou retirez un filtre.';

  @override
  String get searchClearFilters => 'Effacer les filtres';

  @override
  String get searchStartTitle => 'Rechercher dans le coffre';

  @override
  String get searchStartBody =>
      'Nom, type, description, tags ou nom du fichier. Majuscules et accents sont ignorés.';

  @override
  String get searchFilterCategory => 'Catégorie';

  @override
  String get searchFilterTag => 'Tag';

  @override
  String get searchFilterFavorites => 'Favoris';

  @override
  String get searchFilterFormat => 'Format';

  @override
  String get searchFilterAdded => 'Ajouté';

  @override
  String get searchFilterExpiry => 'Expiration';

  @override
  String get searchAddedWeek => '7 derniers jours';

  @override
  String get searchAddedMonth => '30 derniers jours';

  @override
  String get searchAddedYear => '12 derniers mois';

  @override
  String get searchExpiryExpired => 'Expirés';

  @override
  String get searchExpiry30 => 'Dans les 30 jours';

  @override
  String get searchExpiry365 => 'Dans l\'année';

  @override
  String get searchExpiryNone => 'Sans date';

  @override
  String get searchAny => 'Tous';

  @override
  String get searchNoTags => 'Aucun tag pour l\'instant.';

  @override
  String searchMatchTag(String tags) {
    return 'Tag : $tags';
  }

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
  String get errorScanner =>
      'Le scanner n\'a pas pu s\'ouvrir. Vérifiez l\'accès à l\'appareil photo dans les réglages du téléphone.';

  @override
  String get errorUnexpected =>
      'Quelque chose n\'a pas fonctionné. Réessayez dans un instant.';
}
