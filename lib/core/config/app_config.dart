/// Constantes de configuration de l'application.
///
/// Les valeurs viennent de docs/04-securite.md et docs/01-analyse.md.
abstract final class AppConfig {
  /// Longueur du code : 6 à 12 chiffres (D5).
  /// Adresse de l'assistance, affichée dans « Aide et assistance ».
  /// `null` tant que le développeur ne l'a pas choisie : aucune adresse
  /// fictive n'est affichée (docs/publication/README.md).
  static const String? supportEmail = null;

  static const int pinMinLength = 6;
  static const int pinMaxLength = 12;

  /// Essais libres avant la première attente (§5).
  static const int pinFreeAttempts = 5;

  /// Attentes successives après les essais libres (§5).
  static const List<Duration> pinLockoutSteps = [
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(hours: 1),
  ];

  /// Délai de verrouillage après inactivité, par défaut (D12).
  static const Duration defaultAutoLock = Duration(minutes: 2);

  /// Choix proposés pour le délai de verrouillage (D12).
  static const List<Duration> autoLockChoices = [
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 5),
    Duration(minutes: 10),
  ];

  /// Tolérance maximale en arrière-plan pendant une opération lancée par
  /// DocSafe (scanner, sélecteur, partage, fenêtre biométrique) (§10).
  static const Duration externalOperationTolerance = Duration(minutes: 5);

  /// Une authentification récente n'est pas redemandée (§11).
  static const Duration reauthGracePeriod = Duration(seconds: 30);

  /// Le presse-papiers est vidé après ce délai (§7).
  static const Duration clipboardClearDelay = Duration(seconds: 60);

  /// Taille d'un bloc chiffré (§8).
  static const int cipherBlockSize = 1024 * 1024;

  /// Version du schéma de la base.
  static const int databaseSchemaVersion = 1;

  /// Nom du fichier de la base et du fichier de la serrure de récupération.
  static const String databaseFileName = 'docusafe.db';
  static const String recoverySlotFileName = 'recovery.slot';
}

/// Limites des documents.
abstract final class DocumentLimits {
  /// Taille maximale d'un fichier importé.
  static const int maxFileSizeBytes = 100 * 1000 * 1000;

  /// Au-delà, un document est déchiffré dans un fichier temporaire plutôt
  /// qu'en mémoire (docs/04-securite.md §12).
  static const int maxInMemoryBytes = 20 * 1000 * 1000;

  /// Plus grand côté d'une miniature, en pixels.
  static const int thumbnailMaxSide = 512;

  /// Qualité JPEG des miniatures.
  static const int thumbnailJpegQuality = 80;

  /// Longueur maximale d'un titre.
  static const int maxTitleLength = 200;
}
