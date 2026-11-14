import 'dart:convert';

import 'package:drift/drift.dart';

import '../../config/app_config.dart';
import '../app_database.dart';
import '../tables.dart';

part 'settings_dao.g.dart';

/// Réglages du coffre (ligne unique `id = 1`).
@DriftAccessor(tables: [VaultSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<VaultSettingsRow> get() =>
      (select(vaultSettings)..where((s) => s.id.equals(1))).getSingle();

  Stream<VaultSettingsRow> watch() =>
      (select(vaultSettings)..where((s) => s.id.equals(1))).watchSingle();

  Future<void> setBiometricEnabled(bool enabled) => _write(
    VaultSettingsCompanion(biometricEnabled: Value(enabled)),
  );

  Future<void> setAutoLock(Duration duration) => _write(
    VaultSettingsCompanion(autoLockDuration: Value(duration.inSeconds)),
  );

  Future<void> setNotificationsEnabled(bool enabled) => _write(
    VaultSettingsCompanion(notificationsEnabled: Value(enabled)),
  );

  /// Observe un indicateur booléen du JSON `vault_configuration`.
  Stream<bool> watchFlag(String key) =>
      watch().map((row) => _decode(row.vaultConfiguration)[key] == true);

  /// Lit un réglage du JSON `vault_configuration`.
  Future<Object?> readConfig(String key) async {
    final row = await get();
    return _decode(row.vaultConfiguration)[key];
  }

  /// Écrit un réglage dans le JSON `vault_configuration`.
  Future<void> writeConfig(String key, Object? value) async {
    final row = await get();
    final map = _decode(row.vaultConfiguration);
    if (value == null) {
      map.remove(key);
    } else {
      map[key] = value;
    }
    await _write(VaultSettingsCompanion(vaultConfiguration: Value(jsonEncode(map))));
  }

  Future<void> _write(VaultSettingsCompanion companion) =>
      (update(vaultSettings)..where((s) => s.id.equals(1))).write(companion);

  static Map<String, Object?> _decode(String raw) {
    try {
      return (jsonDecode(raw) as Map).cast<String, Object?>();
    } on FormatException {
      return {};
    }
  }
}

/// Clés du JSON `vault_configuration` et valeurs par défaut.
abstract final class VaultConfigKeys {
  /// Délais de rappel par défaut, en jours avant l'expiration.
  static const reminderOffsets = 'reminder_offsets';
  static const List<int> defaultReminderOffsets = [90, 30, 7, 0];

  /// Heure des rappels, `HH:mm`.
  static const reminderTime = 'reminder_time';
  static const String defaultReminderTime = '09:00';

  /// Afficher le nom du document dans les notifications (faux par défaut).
  static const notificationShowsTitle = 'notification_shows_title';

  /// Captures d'écran autorisées (faux par défaut).
  static const screenshotsAllowed = 'screenshots_allowed';

  /// Nom du profil local (facultatif).
  static const profileName = 'profile_name';

  /// La demande d'autorisation des notifications a déjà été faite.
  static const notificationPermissionAsked = 'notification_permission_asked';

  /// L'utilisateur a confirmé avoir conservé sa clé de récupération (D6 révisée).
  static const recoveryKeyConfirmed = 'recovery_key_confirmed';

  /// Dernière sauvegarde : date (ISO 8601) et taille du fichier, en octets.
  static const lastBackupAt = 'last_backup_at';
  static const lastBackupSize = 'last_backup_size';

  static Duration autoLockOf(VaultSettingsRow row) =>
      Duration(seconds: row.autoLockDuration > 0
          ? row.autoLockDuration
          : AppConfig.defaultAutoLock.inSeconds);
}
