import 'dart:io';

import 'package:flutter/services.dart';

import '../utils/app_log.dart';

/// Accès du scanner à l'appareil photo.
enum CameraAccess {
  /// Android : aucune autorisation. Le scanner ML Kit tourne dans les
  /// services Google Play ; le scanner de secours passe par l'application
  /// Appareil photo du téléphone (docs/04-securite.md §16).
  notNeeded,
  granted,
  denied,

  /// iPhone : pas encore demandé.
  notDetermined,
}

/// Réglages du téléphone (Paramètres → Autorisations) : accès à l'appareil
/// photo sur iPhone, ouverture de la page de DocSafe dans les réglages.
abstract interface class SystemSettingsService {
  Future<CameraAccess> cameraAccess();

  /// Demande l'appareil photo (iPhone : fenêtre du système, une seule fois).
  Future<CameraAccess> requestCameraAccess();

  /// Ouvre la page de DocSafe dans les réglages du téléphone ;
  /// [notifications] : directement ses notifications (Android). Retourne
  /// vrai si la page s'est ouverte.
  Future<bool> openAppSettings({bool notifications = false});
}

final class PlatformSystemSettingsService implements SystemSettingsService {
  const PlatformSystemSettingsService();

  static const MethodChannel _channel = MethodChannel('docusafe/platform');

  @override
  Future<CameraAccess> cameraAccess() async {
    if (!Platform.isIOS) {
      return CameraAccess.notNeeded;
    }
    return _invokeCamera('cameraAccess');
  }

  @override
  Future<CameraAccess> requestCameraAccess() async {
    if (!Platform.isIOS) {
      return CameraAccess.notNeeded;
    }
    return _invokeCamera('requestCameraAccess');
  }

  /// À vérifier sur iOS.
  Future<CameraAccess> _invokeCamera(String method) async {
    try {
      return switch (await _channel.invokeMethod<String>(method)) {
        'granted' => CameraAccess.granted,
        'notDetermined' => CameraAccess.notDetermined,
        _ => CameraAccess.denied,
      };
    } on Object catch (e, s) {
      AppLog.error('settings.camera', e, s);
      return CameraAccess.denied;
    }
  }

  @override
  Future<bool> openAppSettings({bool notifications = false}) async {
    try {
      return await _channel.invokeMethod<bool>('openAppSettings', {
            'notifications': notifications,
          }) ??
          false;
    } on Object catch (e, s) {
      AppLog.error('settings.open', e, s);
      return false;
    }
  }
}

/// Version simulée (tests).
final class FakeSystemSettingsService implements SystemSettingsService {
  CameraAccess camera = CameraAccess.notNeeded;

  /// État obtenu après une demande.
  CameraAccess cameraAfterRequest = CameraAccess.granted;
  int openCalls = 0;
  bool? lastOpenedNotifications;
  int cameraRequests = 0;

  @override
  Future<CameraAccess> cameraAccess() async => camera;

  @override
  Future<CameraAccess> requestCameraAccess() async {
    cameraRequests++;
    return camera = cameraAfterRequest;
  }

  @override
  Future<bool> openAppSettings({bool notifications = false}) async {
    openCalls++;
    lastOpenedNotifications = notifications;
    return true;
  }
}
