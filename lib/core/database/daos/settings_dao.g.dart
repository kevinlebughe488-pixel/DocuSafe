// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_dao.dart';

// ignore_for_file: type=lint
mixin _$SettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $VaultSettingsTable get vaultSettings => attachedDatabase.vaultSettings;
  SettingsDaoManager get managers => SettingsDaoManager(this);
}

class SettingsDaoManager {
  final _$SettingsDaoMixin _db;
  SettingsDaoManager(this._db);
  $$VaultSettingsTableTableManager get vaultSettings =>
      $$VaultSettingsTableTableManager(_db.attachedDatabase, _db.vaultSettings);
}
