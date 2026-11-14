/// Adresses des écrans (docs/02-architecture.md §5).
abstract final class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const setup = '/setup';
  static const lock = '/lock';
  static const lockRecovery = '/lock/recovery';

  // Onglets principaux (coque avec barre du bas).
  static const home = '/home';
  static const documents = '/documents';
  static const scan = '/scan';
  static const deadlines = '/deadlines';
  static const settings = '/settings';

  /// Rappels d'un document.
  static String documentReminders(String id) => '/deadlines/$id/reminders';

  // Scanner et recherche (plein écran).
  static const scanPreview = '/scan/preview';
  static const search = '/search';

  // Documents (plein écran).
  static const documentsImport = '/documents/import';
  static const documentsImportInfo = '/documents/import/info';
  static String document(String id) => '/documents/$id';
  static String documentView(String id) => '/documents/$id/view';
  static String documentEdit(String id) => '/documents/$id/edit';
  static String documentDelete(String id) => '/documents/$id/delete';

  /// Liste filtrée par catégorie.
  static String documentsOfCategory(String categoryId) =>
      '/documents?category=$categoryId';
  static const documentsFavorites = '/documents?tab=favorites';
  static const documentsRecent = '/documents?tab=recent';

  // Catégories.
  static const categories = '/categories';
  static const categoryNew = '/categories/new';
  static String category(String id) => '/categories/$id';

  // Paramètres.
  static const settingsSecurity = '/settings/security';
  static const settingsChangePin = '/settings/security/pin';
  static const settingsRecoveryKey = '/settings/security/recovery-key';
  static const settingsAbout = '/settings/about';
  static const settingsNotifications = '/settings/notifications';

  /// Première prise de note de la clé, depuis le rappel de l'accueil.
  static const recoveryKeyFirstTime = '/settings/security/recovery-key?first=1';

  static const legalPrivacy = '/legal/privacy';
  static const legalTerms = '/legal/terms';

  /// Écrans accessibles quel que soit l'état du coffre.
  static bool isPublic(String location) => location.startsWith('/legal/');
}
