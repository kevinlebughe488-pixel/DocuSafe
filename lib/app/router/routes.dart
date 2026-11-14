/// Adresses des écrans (docs/02-architecture.md §5).
abstract final class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const setup = '/setup';
  static const lock = '/lock';
  static const lockRecovery = '/lock/recovery';
  static const home = '/home';
  static const settingsSecurity = '/settings/security';
  static const settingsChangePin = '/settings/security/pin';
  static const settingsRecoveryKey = '/settings/security/recovery-key';

  /// Première prise de note de la clé, depuis le rappel de l'accueil.
  static const recoveryKeyFirstTime = '/settings/security/recovery-key?first=1';
  static const legalPrivacy = '/legal/privacy';
  static const legalTerms = '/legal/terms';

  /// Écrans accessibles quel que soit l'état du coffre.
  static bool isPublic(String location) => location.startsWith('/legal/');
}
