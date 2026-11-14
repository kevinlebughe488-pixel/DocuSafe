import 'package:material_ui/material_ui.dart' show Locale;

import '../../app/l10n/generated/app_localizations.dart';
import '../database/app_database.dart';
import '../database/daos/settings_dao.dart';
import '../platform/notification_service.dart';
import '../utils/app_log.dart';
import '../utils/date_only.dart';
import 'reminder_planner.dart';

/// Réglages des rappels (Paramètres → Notifications).
final class ReminderSettings {
  const ReminderSettings({
    required this.enabled,
    required this.defaultOffsets,
    required this.time,
    required this.showTitle,
  });

  final bool enabled;
  final List<int> defaultOffsets;
  final (int, int) time;
  final bool showTitle;
}

/// Cas d'utilisation `SyncReminders` (docs/02-architecture.md §1) : calcule
/// les rappels à partir des dates d'expiration et programme les
/// notifications. L'onglet Échéances reste la référence si une notification
/// est manquée (risque R6).
final class ReminderService {
  ReminderService({
    required AppDatabase database,
    required this._notifications,
    DateTime Function()? clock,
  }) : _db = database,
       _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final NotificationService _notifications;
  final DateTime Function() _clock;

  Future<ReminderSettings> settings() async {
    final row = await _db.settingsDao.get();
    final offsets = await _db.settingsDao.readConfig(VaultConfigKeys.reminderOffsets);
    final time = await _db.settingsDao.readConfig(VaultConfigKeys.reminderTime);
    final showTitle = await _db.settingsDao.readConfig(VaultConfigKeys.notificationShowsTitle);
    return ReminderSettings(
      enabled: row.notificationsEnabled,
      defaultOffsets: offsets is List
          ? ReminderPlanner.normalizeOffsets(offsets.whereType<int>())
          : ReminderPlanner.defaultOffsets,
      time: ReminderPlanner.parseTime(time is String ? time : null),
      showTitle: showTitle == true,
    );
  }

  /// À appeler après chaque ajout ou modification de la date d'expiration
  /// d'un document. Première date : rappels par défaut. Date modifiée : les
  /// délais existants (et leur état) sont conservés, les dates recalculées.
  /// Date retirée : rappels supprimés.
  Future<void> syncDocument(String documentId) async {
    final doc = await _db.documentsDao.getById(documentId);
    final expiration = doc?.expirationDate;
    if (doc == null || expiration == null) {
      await _db.remindersDao.deleteForDocument(documentId);
    } else {
      final s = await settings();
      final existing = await _db.remindersDao.getForDocument(documentId);
      final offsets = existing.isEmpty
          ? s.defaultOffsets
          : existing.map((r) => r.offsetDays).toList();
      await _db.remindersDao.replaceForDocument(documentId, {
        for (final o in offsets) o: ReminderPlanner.dateFor(expiration, o, s.time),
      });
    }
    await rescheduleAll();
  }

  /// Ajoute un délai personnalisé à un document.
  Future<void> addOffset(String documentId, int offsetDays) async {
    final doc = await _db.documentsDao.getById(documentId);
    final expiration = doc?.expirationDate;
    if (expiration == null) {
      return;
    }
    final s = await settings();
    final existing = await _db.remindersDao.getForDocument(documentId);
    final offsets = ReminderPlanner.normalizeOffsets([
      ...existing.map((r) => r.offsetDays),
      offsetDays,
    ]);
    await _db.remindersDao.replaceForDocument(documentId, {
      for (final o in offsets) o: ReminderPlanner.dateFor(expiration, o, s.time),
    });
    await rescheduleAll();
  }

  Future<void> setEnabled(String reminderId, bool enabled) async {
    await _db.remindersDao.setEnabled(reminderId, enabled);
    await rescheduleAll();
  }

  /// Recalcule les dates de tous les rappels (nouvelle heure d'envoi).
  Future<void> recomputeAllDates() async {
    final s = await settings();
    final docs = await (_db.select(_db.documents)
          ..where((d) => d.expirationDate.isNotNull()))
        .get();
    for (final doc in docs) {
      final existing = await _db.remindersDao.getForDocument(doc.id);
      if (existing.isEmpty) {
        continue;
      }
      await _db.remindersDao.replaceForDocument(doc.id, {
        for (final r in existing)
          r.offsetDays: ReminderPlanner.dateFor(doc.expirationDate!, r.offsetDays, s.time),
      });
    }
    await rescheduleAll();
  }

  /// Programme les 60 prochains rappels actifs (au déverrouillage et après
  /// chaque modification). Les rappels déjà passés ne sont pas programmés.
  Future<void> rescheduleAll() async {
    try {
      final s = await settings();
      if (!s.enabled) {
        await _notifications.cancelAll();
        return;
      }
      final l10n = lookupAppLocalizations(const Locale('fr'));
      final upcoming = await _db.remindersDao.upcoming(
        _clock(),
        limit: ReminderPlanner.maxScheduled,
      );
      await _notifications.replaceAll([
        for (final u in upcoming)
          ScheduledNotification(
            id: u.reminder.notificationId,
            when: u.reminder.reminderDate.toLocal(),
            title: s.showTitle
                ? l10n.notificationTitleNamed(u.documentTitle, u.reminder.offsetDays)
                : l10n.notificationTitle(u.reminder.offsetDays),
            body: l10n.notificationBody,
            payload: u.reminder.documentId,
          ),
      ]);
    } on Object catch (e, s) {
      AppLog.error('reminders.reschedule', e, s);
    }
  }

  /// Aucune date d'expiration n'a encore déclenché la demande d'autorisation.
  Future<bool> shouldAskPermission() async =>
      await _db.settingsDao.readConfig(VaultConfigKeys.notificationPermissionAsked) != true;

  Future<bool> requestPermission() async {
    await _db.settingsDao.writeConfig(VaultConfigKeys.notificationPermissionAsked, true);
    return _notifications.requestPermission();
  }

  /// Aujourd'hui, pour les écrans.
  DateOnly today() => DateOnly.fromDateTime(_clock());
}
