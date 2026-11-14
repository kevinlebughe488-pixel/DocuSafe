import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../utils/app_log.dart';

/// Notification à programmer.
final class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;

  /// Moment local.
  final DateTime when;
  final String title;
  final String body;

  /// Identifiant du document, rouvert quand la notification est touchée.
  final String payload;
}

/// Notifications locales (docs/04-securite.md §14) : aucun serveur,
/// alarmes « inexactes », texte générique par défaut.
abstract interface class NotificationService {
  /// Prépare le service. [onTap] reçoit l'identifiant du document quand une
  /// notification est touchée alors que l'application est ouverte.
  Future<void> initialize({required void Function(String payload) onTap});

  /// Identifiant du document si l'application a été lancée en touchant une
  /// notification.
  Future<String?> launchPayload();

  /// Demande l'autorisation du système (Android 13 et plus, iOS).
  Future<bool> requestPermission();

  /// Remplace toutes les notifications programmées par [notifications].
  Future<void> replaceAll(List<ScheduledNotification> notifications);

  Future<void> cancelAll();
}

final class PlatformNotificationService implements NotificationService {
  PlatformNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static const _channel = AndroidNotificationDetails(
    'deadlines',
    'Rappels d’échéance',
    channelDescription: 'Rappels avant la date d’expiration d’un document',
    // Écran verrouillé : le texte est déjà générique par défaut.
    visibility: NotificationVisibility.private,
  );

  @override
  Future<void> initialize({required void Function(String payload) onTap}) async {
    if (_ready || kIsWeb) {
      return;
    }
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Object catch (e, s) {
      AppLog.error('notifications.timezone', e, s);
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // La permission n'est demandée qu'à la première date d'expiration.
        // À vérifier sur iOS.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) {
          onTap(payload);
        }
      },
    );
    _ready = true;
  }

  @override
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details!.notificationResponse?.payload;
    }
    return null;
  }

  @override
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, sound: true) ??
          false;
    }
    return false;
  }

  @override
  Future<void> replaceAll(List<ScheduledNotification> notifications) async {
    await _plugin.cancelAll();
    for (final n in notifications) {
      try {
        await _plugin.zonedSchedule(
          id: n.id,
          scheduledDate: tz.TZDateTime.from(n.when, tz.local),
          notificationDetails: const NotificationDetails(
            android: _channel,
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: n.title,
          body: n.body,
          payload: n.payload,
        );
      } on Object catch (e, s) {
        AppLog.error('notifications.schedule', e, s);
      }
    }
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}

/// Version simulée : garde en mémoire ce qui serait programmé (tests).
final class FakeNotificationService implements NotificationService {
  List<ScheduledNotification> scheduled = [];
  bool permissionGranted = true;
  int permissionRequests = 0;
  String? pendingLaunchPayload;
  void Function(String payload)? _onTap;

  /// Simule une notification touchée.
  void tap(String payload) => _onTap?.call(payload);

  @override
  Future<void> initialize({required void Function(String payload) onTap}) async =>
      _onTap = onTap;

  @override
  Future<String?> launchPayload() async => pendingLaunchPayload;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> replaceAll(List<ScheduledNotification> notifications) async =>
      scheduled = List.of(notifications);

  @override
  Future<void> cancelAll() async => scheduled = [];
}
