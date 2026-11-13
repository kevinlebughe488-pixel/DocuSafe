import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../core/config/app_config.dart';
import '../../../core/database/daos/settings_dao.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers.dart';
import '../../../core/security/auth/biometric_service.dart';
import '../../../core/security/lock/vault_state.dart';
import '../../../core/utils/app_log.dart';
import '../../../core/utils/error_messages.dart';

/// Message bref à afficher, résolu avec les textes de l'application.
final class SettingsMessage {
  const SettingsMessage.text(String Function(AppLocalizations) resolver)
    : _resolver = resolver;

  SettingsMessage.error(Object error)
    : _resolver = ((l10n) => ErrorMessages.of(l10n, error));

  final String Function(AppLocalizations) _resolver;

  String resolve(AppLocalizations l10n) => _resolver(l10n);
}

final class SecuritySettingsState {
  const SecuritySettingsState({
    this.biometricKind = BiometricKind.none,
    this.biometricEnabled = false,
    this.autoLock = AppConfig.defaultAutoLock,
    this.screenSecure = true,
    this.busy = false,
    this.message,
  });

  final BiometricKind biometricKind;
  final bool biometricEnabled;
  final Duration autoLock;
  final bool screenSecure;
  final bool busy;
  final SettingsMessage? message;

  SecuritySettingsState copyWith({
    BiometricKind? biometricKind,
    bool? biometricEnabled,
    Duration? autoLock,
    bool? screenSecure,
    bool? busy,
    SettingsMessage? message,
    bool clearMessage = false,
  }) => SecuritySettingsState(
    biometricKind: biometricKind ?? this.biometricKind,
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    autoLock: autoLock ?? this.autoLock,
    screenSecure: screenSecure ?? this.screenSecure,
    busy: busy ?? this.busy,
    message: clearMessage ? null : (message ?? this.message),
  );
}

final class SecuritySettingsViewModel extends Notifier<SecuritySettingsState> {
  @override
  SecuritySettingsState build() {
    unawaited(_load());
    return const SecuritySettingsState();
  }

  Future<void> _load() async {
    final vault = ref.read(vaultControllerProvider);
    if (vault is! VaultUnlocked) {
      return;
    }
    try {
      final settings = await vault.session.database.settingsDao.get();
      final service = ref.read(vaultServiceProvider);
      final kind = await ref.read(biometricServiceProvider).availableKind();
      state = state.copyWith(
        biometricKind: kind,
        biometricEnabled: await service.isBiometricEnabled(),
        autoLock: VaultConfigKeys.autoLockOf(settings),
        screenSecure: await service.isScreenSecure(),
      );
    } on Object catch (e, s) {
      AppLog.error('settings.load', e, s);
    }
  }

  void clearMessage() => state = state.copyWith(clearMessage: true);

  Future<void> setBiometrics(bool enabled) async {
    state = state.copyWith(busy: true);
    final controller = ref.read(vaultControllerProvider.notifier);
    try {
      if (enabled) {
        await controller.enableBiometrics();
      } else {
        await controller.disableBiometrics();
      }
      state = state.copyWith(
        busy: false,
        biometricEnabled: enabled,
        message: SettingsMessage.text(
          (l10n) => enabled
              ? l10n.settingsBiometricEnabled
              : l10n.settingsBiometricDisabled,
        ),
      );
    } on AppException catch (e, s) {
      AppLog.error('settings.biometric', e, s);
      state = state.copyWith(busy: false, message: SettingsMessage.error(e));
    }
  }

  Future<void> setAutoLock(Duration duration) async {
    try {
      await ref.read(vaultControllerProvider.notifier).setAutoLock(duration);
      state = state.copyWith(autoLock: duration);
    } on AppException catch (e) {
      state = state.copyWith(message: SettingsMessage.error(e));
    }
  }

  Future<void> setScreenshotsAllowed(bool allowed) async {
    state = state.copyWith(busy: true);
    try {
      await ref.read(vaultControllerProvider.notifier).setScreenSecure(!allowed);
      state = state.copyWith(busy: false, screenSecure: !allowed);
    } on AppException catch (e) {
      state = state.copyWith(busy: false, message: SettingsMessage.error(e));
    }
  }
}

final securitySettingsProvider =
    NotifierProvider<SecuritySettingsViewModel, SecuritySettingsState>(
      SecuritySettingsViewModel.new,
    );
