import 'package:drift/drift.dart';

import '../../utils/secure_random.dart';
import '../app_database.dart';
import '../tables.dart';

part 'reminders_dao.g.dart';

/// Rappel à programmer, avec le titre du document (pour la notification si
/// l'utilisateur a choisi d'afficher le nom).
final class UpcomingReminder {
  const UpcomingReminder(this.reminder, this.documentTitle);

  final ReminderRow reminder;
  final String documentTitle;
}

/// Accès aux rappels d'échéance (docs/03-modele-de-donnees.md §2.5).
@DriftAccessor(tables: [Reminders, Documents])
class RemindersDao extends DatabaseAccessor<AppDatabase> with _$RemindersDaoMixin {
  RemindersDao(super.db);

  Stream<List<ReminderRow>> watchForDocument(String documentId) =>
      (select(reminders)
            ..where((r) => r.documentId.equals(documentId))
            ..orderBy([(r) => OrderingTerm.desc(r.offsetDays)]))
          .watch();

  Future<List<ReminderRow>> getForDocument(String documentId) =>
      (select(reminders)..where((r) => r.documentId.equals(documentId))).get();

  /// Remplace les rappels d'un document par [planned] (délai → moment).
  /// Un délai déjà présent garde son identifiant, son numéro de
  /// notification et son état (activé ou non) ; seule la date change.
  Future<void> replaceForDocument(
    String documentId,
    Map<int, DateTime> planned,
  ) => transaction(() async {
    final existing = {
      for (final r in await getForDocument(documentId)) r.offsetDays: r,
    };
    for (final r in existing.values) {
      if (!planned.containsKey(r.offsetDays)) {
        await (delete(reminders)..where((x) => x.id.equals(r.id))).go();
      }
    }
    var nextId = await _nextNotificationId();
    for (final entry in planned.entries) {
      final current = existing[entry.key];
      if (current != null) {
        await (update(reminders)..where((x) => x.id.equals(current.id))).write(
          RemindersCompanion(reminderDate: Value(entry.value)),
        );
      } else {
        await into(reminders).insert(
          RemindersCompanion.insert(
            id: SecureRandom.uuid(),
            documentId: documentId,
            reminderDate: entry.value,
            offsetDays: entry.key,
            notificationId: nextId++,
          ),
        );
      }
    }
  });

  Future<void> deleteForDocument(String documentId) =>
      (delete(reminders)..where((r) => r.documentId.equals(documentId))).go();

  Future<void> setEnabled(String reminderId, bool enabled) =>
      (update(reminders)..where((r) => r.id.equals(reminderId))).write(
        RemindersCompanion(isEnabled: Value(enabled)),
      );

  /// Rappels actifs à venir, les plus proches d'abord.
  Future<List<UpcomingReminder>> upcoming(DateTime after, {required int limit}) {
    final query = select(reminders).join([
      innerJoin(documents, documents.id.equalsExp(reminders.documentId)),
    ])
      ..where(reminders.isEnabled.equals(true) & reminders.reminderDate.isBiggerThanValue(after))
      ..orderBy([OrderingTerm.asc(reminders.reminderDate)])
      ..limit(limit);
    return query
        .map((r) => UpcomingReminder(r.readTable(reminders), r.readTable(documents).title))
        .get();
  }

  Future<int> _nextNotificationId() async {
    final max = reminders.notificationId.max();
    final value = await (selectOnly(reminders)..addColumns([max]))
        .map((r) => r.read(max))
        .getSingle();
    return (value ?? 999) + 1;
  }
}
