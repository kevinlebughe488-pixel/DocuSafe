import 'package:docusafe/core/database/app_database.dart';
import 'package:docusafe/core/database/daos/settings_dao.dart';
import 'package:docusafe/core/database/default_categories.dart';
import 'package:docusafe/core/database/tables.dart';
import 'package:docusafe/core/platform/notification_service.dart';
import 'package:docusafe/core/reminders/reminder_planner.dart';
import 'package:docusafe/core/reminders/reminder_service.dart';
import 'package:docusafe/core/utils/date_only.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late FakeNotificationService notifications;
  late ReminderService service;
  final now = DateTime(2026, 11, 14, 12);

  Future<void> addDoc(String id, String title, DateOnly? expiration) async {
    await db.documentsDao.insertDocument(
      DocumentsCompanion.insert(
        id: id,
        title: title,
        categoryId: DefaultCategory.othersId,
        fileName: '$id.pdf',
        encryptedFilePath: 'files/$id.dsf',
        fileType: DocumentFileType.pdf,
        fileSize: 1,
        createdAt: now,
        updatedAt: now,
        expirationDate: Value(expiration),
        integrityHash: 'h$id',
      ),
    );
    await service.syncDocument(id);
  }

  Future<void> setExpiration(String id, DateOnly? date) async {
    await db.documentsDao.updateDocument(id, DocumentsCompanion(expirationDate: Value(date)));
    await service.syncDocument(id);
  }

  setUp(() {
    db = AppDatabase.inMemory();
    notifications = FakeNotificationService();
    service = ReminderService(database: db, notifications: notifications, clock: () => now);
  });
  tearDown(() => db.close());

  test('heure d\'envoi et délais', () {
    expect(ReminderPlanner.parseTime('08:30'), (8, 30));
    expect(ReminderPlanner.parseTime('25:00'), (9, 0));
    expect(ReminderPlanner.parseTime(null), (9, 0));
    expect(ReminderPlanner.dateFor(const DateOnly(2027, 3, 1), 7, (9, 0)), DateTime(2027, 2, 22, 9));
    expect(ReminderPlanner.normalizeOffsets([7, 90, 7, 0, -1]), [90, 7, 0]);
  });

  test('première date : quatre rappels, seuls les futurs sont programmés', () async {
    // Expiration dans 20 jours : 90 et 30 jours avant sont déjà passés.
    await addDoc('a', 'Visa', const DateOnly(2026, 12, 4));
    final rows = await db.remindersDao.getForDocument('a');
    expect(rows.map((r) => r.offsetDays).toSet(), {90, 30, 7, 0});
    expect(notifications.scheduled.length, 2);
    final first = notifications.scheduled.first;
    expect(first.when, DateTime(2026, 11, 27, 9));
    expect(first.title, 'Échéance dans 7 jours');
    expect(first.body, 'Un document de votre coffre arrive à échéance.');
    expect(first.title.contains('Visa'), isFalse);
    expect(first.payload, 'a');
    expect(notifications.scheduled.last.title, "Échéance aujourd'hui");
  });

  test('nom affiché si l\'utilisateur l\'a choisi', () async {
    await db.settingsDao.writeConfig(VaultConfigKeys.notificationShowsTitle, true);
    await addDoc('a', 'Visa', const DateOnly(2026, 12, 4));
    expect(notifications.scheduled.first.title, 'Visa expire dans 7 jours');
  });

  test('désactiver, ajouter un délai, changer la date, retirer la date', () async {
    await addDoc('a', 'Passeport', const DateOnly(2027, 6, 1));
    expect(notifications.scheduled.length, 4);
    final seven = (await db.remindersDao.getForDocument('a')).firstWhere((r) => r.offsetDays == 7);
    await service.setEnabled(seven.id, false);
    expect(notifications.scheduled.length, 3);

    await service.addOffset('a', 14);
    expect((await db.remindersDao.getForDocument('a')).length, 5);
    expect(notifications.scheduled.length, 4);

    // Nouvelle date : délais et état conservés, dates recalculées.
    await setExpiration('a', const DateOnly(2027, 9, 1));
    final rows = await db.remindersDao.getForDocument('a');
    expect(rows.length, 5);
    final sevenAfter = rows.firstWhere((r) => r.offsetDays == 7);
    expect(sevenAfter.id, seven.id);
    expect(sevenAfter.notificationId, seven.notificationId);
    expect(sevenAfter.isEnabled, isFalse);
    expect(sevenAfter.reminderDate.toLocal(), DateTime(2027, 8, 25, 9));

    await setExpiration('a', null);
    expect(await db.remindersDao.getForDocument('a'), isEmpty);
    expect(notifications.scheduled, isEmpty);
  });

  test('rappels désactivés dans les réglages : rien n\'est programmé', () async {
    await addDoc('a', 'Passeport', const DateOnly(2027, 6, 1));
    await db.settingsDao.setNotificationsEnabled(false);
    await service.rescheduleAll();
    expect(notifications.scheduled, isEmpty);
  });

  test('nouvelle heure d\'envoi et limite de 60 rappels', () async {
    for (var i = 0; i < 20; i++) {
      await addDoc('d$i', 'Doc $i', DateOnly(2027, 6, 1 + i));
    }
    expect(notifications.scheduled.length, ReminderPlanner.maxScheduled);
    await db.settingsDao.writeConfig(VaultConfigKeys.reminderTime, '18:15');
    await service.recomputeAllDates();
    expect(notifications.scheduled.first.when.hour, 18);
    expect(notifications.scheduled.first.when.minute, 15);
  });

  test('demande d\'autorisation une seule fois', () async {
    expect(await service.shouldAskPermission(), isTrue);
    expect(await service.requestPermission(), isTrue);
    expect(await service.shouldAskPermission(), isFalse);
    expect(notifications.permissionRequests, 1);
  });
}
