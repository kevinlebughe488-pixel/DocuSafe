import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import '../../database/daos/settings_dao.dart';
import '../../errors/app_exception.dart';
import '../../providers.dart';
import '../../utils/app_log.dart';
import '../keys/recovery_key.dart';
import '../screen/screen_security.dart';
import '../vault_service.dart';
import 'vault_session.dart';
import 'vault_state.dart';

/// Cycle de vie du coffre : création, déverrouillage, verrouillage
/// (immédiat en arrière-plan, après inactivité, à la demande).
///
/// C'est l'unique détenteur de la [VaultSession]. Les écrans et les autres
/// providers lisent la session à travers l'état.
final class VaultController extends Notifier<VaultState> {
  late final VaultService _service;
  late final ScreenSecurity _screenSecurity;
  late final DateTime Function() _clock;

  Timer? _inactivityTimer;
  Duration _autoLock = AppConfig.defaultAutoLock;
  AppLifecycleListener? _lifecycle;
  DateTime? _hiddenSince;
  int _externalOperations = 0;
  DateTime? _lastAuthentication;
  String? _pendingLocation;

  /// Session ouverte, suivie en dehors de l'état pour pouvoir la fermer à la
  /// disparition du contrôleur (l'état n'est plus lisible à ce moment-là).
  VaultSession? _currentSession;

  @override
  VaultState build() {
    _service = ref.read(vaultServiceProvider);
    _screenSecurity = ref.read(screenSecurityProvider);
    _clock = ref.read(clockProvider);
    ref.onDispose(() {
      _inactivityTimer?.cancel();
      _lifecycle?.dispose();
      // Si l'application disparaît avec le coffre ouvert : fermeture propre.
      unawaited(_currentSession?.close());
    });
    _lifecycle = AppLifecycleListener(
      onHide: _onHidden,
      onShow: _onShown,
      onInactive: () {
        // iOS et Android : l'application perd le premier plan (centre de
        // contrôle, fenêtre système). On note l'instant sans verrouiller.
        _hiddenSince ??= _clock();
      },
      onResume: _onShown,
    );
    unawaited(_initialize());
    return const VaultInitializing();
  }

  VaultService get service => _service;

  /// Session en cours, ou `null` si le coffre n'est pas ouvert.
  VaultSession? get session => switch (state) {
    VaultUnlocked(:final session) => session,
    _ => null,
  };

  /// Session en cours, sinon [VaultLockedException].
  VaultSession requireSession() =>
      session ?? (throw const VaultLockedException());

  /// L'utilisateur s'est authentifié il y a moins de 30 secondes (§11).
  bool get recentlyAuthenticated {
    final last = _lastAuthentication;
    return last != null &&
        _clock().difference(last) < AppConfig.reauthGracePeriod;
  }

  void markAuthenticated() => _lastAuthentication = _clock();

  // ---------------------------------------------------------------------------
  // Démarrage
  // ---------------------------------------------------------------------------

  Future<void> _initialize() async {
    try {
      await _screenSecurity.setSecure(await _service.isScreenSecure());
      if (await _service.hasVault()) {
        state = VaultLocked(
          reason: LockReason.startup,
          biometricEnabled: await _service.isBiometricEnabled(),
        );
      } else {
        state = const VaultAbsent();
      }
    } on AppException catch (e, s) {
      AppLog.error('vault.initialize', e, s);
      state = const VaultAbsent();
    }
  }

  // ---------------------------------------------------------------------------
  // Création et déverrouillage
  // ---------------------------------------------------------------------------

  Future<PendingVaultSetup> prepareSetup(String pin) =>
      _service.prepareSetup(pin);

  Future<void> commitSetup(PendingVaultSetup pending) async {
    final session = await _service.commitSetup(pending);
    await _enterUnlocked(session);
  }

  Future<void> unlockWithPin(String pin) async {
    final session = await _service.unlockWithPin(pin);
    await _enterUnlocked(session);
  }

  Future<void> unlockWithRecoveryKey(RecoveryKey key) async {
    final session = await _service.unlockWithRecoveryKey(key);
    await _enterUnlocked(session);
  }

  Future<void> unlockWithBiometrics() async {
    beginExternalOperation();
    try {
      final session = await _service.unlockWithBiometrics();
      await _enterUnlocked(session);
    } on AuthException catch (e) {
      if (e.code == 'auth.biometric_unavailable' && state is VaultLocked) {
        state = VaultLocked(
          reason: LockReason.biometricChanged,
          biometricEnabled: false,
          returnLocation: (state as VaultLocked).returnLocation,
        );
      }
      rethrow;
    } finally {
      endExternalOperation();
    }
  }

  Future<void> _enterUnlocked(VaultSession session) async {
    final returnLocation = switch (state) {
      VaultLocked(:final returnLocation) => returnLocation,
      _ => null,
    };
    try {
      final settings = await session.database.settingsDao.get();
      _autoLock = VaultConfigKeys.autoLockOf(settings);
    } on Object catch (e, s) {
      AppLog.error('vault.settings_read', e, s);
    }
    markAuthenticated();
    _currentSession = session;
    state = VaultUnlocked(session, returnLocation: returnLocation);
    _restartInactivityTimer();
  }

  // ---------------------------------------------------------------------------
  // Verrouillage
  // ---------------------------------------------------------------------------

  /// Verrouille : ferme la base, efface les clés, purge les temporaires.
  Future<void> lock({
    LockReason reason = LockReason.manual,
    String? currentLocation,
  }) async {
    final current = state;
    if (current is! VaultUnlocked) {
      return;
    }
    _inactivityTimer?.cancel();
    _lastAuthentication = null;
    final biometric = await _service.isBiometricEnabled();
    state = VaultLocked(
      reason: reason,
      biometricEnabled: biometric,
      returnLocation: currentLocation ?? _pendingLocation,
    );
    _pendingLocation = null;
    _currentSession = null;
    await current.session.close();
    AppLog.event('vault.locked.${reason.name}');
  }

  /// Adresse à ouvrir dès le déverrouillage (notification touchée alors que
  /// le coffre est verrouillé).
  void openAfterUnlock(String location) {
    final current = state;
    if (current is VaultLocked) {
      state = VaultLocked(
        reason: current.reason,
        biometricEnabled: current.biometricEnabled,
        returnLocation: location,
      );
    } else {
      _pendingLocation = location;
    }
  }

  /// Le routeur signale l'adresse courante : elle sera rouverte après un
  /// verrouillage automatique.
  void rememberLocation(String location) => _pendingLocation = location;

  /// Toute interaction de l'utilisateur relance le compte à rebours.
  void touch() {
    if (state is VaultUnlocked) {
      _restartInactivityTimer();
    }
  }

  void _restartInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_autoLock, () {
      unawaited(lock(reason: LockReason.inactivity));
    });
  }

  /// Nouveau délai choisi dans les paramètres.
  Future<void> setAutoLock(Duration duration) async {
    _autoLock = duration;
    await requireSession().database.settingsDao.setAutoLock(duration);
    _restartInactivityTimer();
  }

  /// Une opération lancée par DocuSafe (scanner, sélecteur, partage, fenêtre
  /// biométrique) fait passer l'application en arrière-plan : tolérance de
  /// cinq minutes au lieu du verrouillage immédiat (docs/04-securite.md §10).
  void beginExternalOperation() => _externalOperations++;

  void endExternalOperation() {
    if (_externalOperations > 0) {
      _externalOperations--;
    }
  }

  void _onHidden() {
    _hiddenSince ??= _clock();
    if (state is! VaultUnlocked) {
      return;
    }
    if (_externalOperations == 0) {
      unawaited(lock(reason: LockReason.background));
    }
  }

  void _onShown() {
    final since = _hiddenSince;
    _hiddenSince = null;
    if (since == null || state is! VaultUnlocked) {
      return;
    }
    if (_clock().difference(since) > AppConfig.externalOperationTolerance) {
      unawaited(lock(reason: LockReason.background));
    } else {
      _restartInactivityTimer();
    }
  }

  // ---------------------------------------------------------------------------
  // Réglages de sécurité
  // ---------------------------------------------------------------------------

  Future<void> changePin(String newPin) async {
    await _service.changePin(requireSession(), newPin);
    markAuthenticated();
  }

  Future<void> enableBiometrics() async {
    beginExternalOperation();
    try {
      await _service.enableBiometrics(requireSession());
    } finally {
      endExternalOperation();
    }
  }

  Future<void> disableBiometrics() => _service.disableBiometrics(session);

  Future<RecoveryKey> regenerateRecoveryKey() =>
      _service.regenerateRecoveryKey(requireSession());

  Future<void> setScreenSecure(bool secure) async {
    await _service.setScreenSecure(secure);
    await _screenSecurity.setSecure(secure);
    await requireSession().database.settingsDao.writeConfig(
      VaultConfigKeys.screenshotsAllowed,
      !secure,
    );
  }

  /// Vérifie le code pour une opération sensible, sans toucher à la session.
  Future<void> verifyPin(String pin) async {
    await _service.verifyPin(pin);
    markAuthenticated();
  }

  /// Efface tout et revient à l'état « aucun coffre ».
  Future<void> wipe() async {
    _inactivityTimer?.cancel();
    final current = session;
    _currentSession = null;
    state = const VaultInitializing();
    await _service.wipe(current);
    await _screenSecurity.setSecure(true);
    state = const VaultAbsent();
  }
}
