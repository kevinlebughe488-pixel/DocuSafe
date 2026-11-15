import 'dart:io';

import 'package:docusafe/core/database/app_database.dart';
import 'package:docusafe/core/database/default_categories.dart';
import 'package:docusafe/core/database/tables.dart';
import 'package:docusafe/core/errors/app_exception.dart';
import 'package:docusafe/core/utils/date_only.dart';
import 'package:docusafe/core/utils/text_normalizer.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Tests de la base chiffrée (docs/03-modele-de-donnees.md).
void main() {
  late Directory dir;
  late File file;
  final key = Uint8List.fromList(List.generate(32, (i) => i + 1));

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('db_test');
    file = File('${dir.path}/docusafe.db');
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  DocumentsCompanion doc(
    String id,
    String title, {
    String category = 'default-identity',
    String? docType,
    String? description,
    DateOnly? expiration,
  }) => DocumentsCompanion.insert(
    id: id,
    title: title,
    docType: Value(docType),
    categoryId: category,
    fileName: '$title.pdf',
    encryptedFilePath: 'files/${id.substring(0, 2)}/$id.dsf',
    fileType: DocumentFileType.pdf,
    fileSize: 1234,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    description: Value(description),
    expirationDate: Value(expiration),
    integrityHash: 'hash-$id',
  );

  test('création, catégories initiales, réglages', () async {
    final db = AppDatabase.openEncrypted(file, key);
    final categories = await db.categoriesDao.getAll();
    expect(categories.map((c) => c.name), [
      'Identité',
      'Éducation',
      'Professionnel',
      'Finances',
      'Immobilier',
      'Santé',
      'Autres',
    ]);
    expect(categories.first.color, CategoryColors.reference['blue']);
    final settings = await db.settingsDao.get();
    expect(settings.autoLockDuration, 120);
    expect(settings.biometricEnabled, isFalse);
    expect(settings.notificationsEnabled, isTrue);
    await db.close();

    // Illisible sans clé, avec un outil SQLite ordinaire.
    final raw = sqlite.sqlite3.open(file.path);
    expect(
      () => raw.select('SELECT count(*) FROM sqlite_master'),
      throwsA(isA<sqlite.SqliteException>()),
    );
    raw.close();

    // Mauvaise clé refusée.
    final wrong = AppDatabase.openEncrypted(
      file,
      Uint8List.fromList(List.generate(32, (i) => 99)),
    );
    await expectLater(
      wrong.ensureOpened(),
      throwsA(same(CryptoException.integrity)),
    );

    // Bonne clé : les données sont toujours là.
    final again = AppDatabase.openEncrypted(file, key);
    expect((await again.categoriesDao.getAll()).length, 7);
    await again.close();
  });

  test('documents, tags, recherche sans accents ni majuscules', () async {
    final db = AppDatabase.openEncrypted(file, key);
    await db.ensureOpened();
    await db.documentsDao.insertDocument(
      doc('a1', 'Passeport', docType: 'Pièce d\'identité'),
      tagNames: ['Voyage', 'urgent'],
    );
    await db.documentsDao.insertDocument(
      doc('b2', 'Diplôme de licence', category: 'default-education'),
      tagNames: ['Études', 'voyage'],
    );
    await db.documentsDao.insertDocument(
      doc('c3', 'Contrat de bail', category: 'default-housing', description: 'Appartement rue Pasteur'),
    );

    expect(await db.documentsDao.searchIds('pass'), ['a1']);
    expect(await db.documentsDao.searchIds('DIPLOME'), ['b2']);
    expect(await db.documentsDao.searchIds('étude'), ['b2']);
    expect((await db.documentsDao.searchIds('voyage')).toSet(), {'a1', 'b2'});
    expect(await db.documentsDao.searchIds('pasteur'), ['c3']);
    expect(await db.documentsDao.searchIds('identite'), ['a1']);
    expect(await db.documentsDao.searchIds('   '), isEmpty);
    expect(await db.documentsDao.searchIds('"*(bizarre'), isEmpty);

    // Un tag n'est enregistré qu'une fois (voyage / Voyage).
    final tags = await db.select(db.tags).get();
    expect(tags.length, 3);
    expect((await db.documentsDao.tagsOf('a1')).length, 2);

    // Modification : l'index suit.
    await db.documentsDao.updateDocument(
      'a1',
      const DocumentsCompanion(title: Value('Carte d\'identité')),
      tagNames: ['perso'],
    );
    // Le nom du fichier d'origine (Passeport.pdf) reste indexé ; l'ancien
    // tag « urgent » et l'ancien titre ne le sont plus.
    expect(await db.documentsDao.searchIds('passeport.pdf'), ['a1']);
    expect(await db.documentsDao.searchIds('urgent'), isEmpty);
    expect(await db.documentsDao.searchIds('carte'), ['a1']);
    expect(await db.documentsDao.searchIds('voyage'), ['b2']);

    // Suppression : index, liens de tags et tags orphelins disparaissent.
    await db.documentsDao.deleteDocument('b2');
    expect(await db.documentsDao.searchIds('diplome'), isEmpty);
    expect((await db.select(db.tags).get()).map((t) => t.name), ['perso']);
    expect(await db.documentsDao.watchCount().first, 2);
    await db.close();
  });

  test('contraintes : catégorie obligatoire, titre non vide, doublon', () async {
    final db = AppDatabase.openEncrypted(file, key);
    await expectLater(
      db.documentsDao.insertDocument(doc('a1', 'X', category: 'inconnue')),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      db.documentsDao.insertDocument(doc('a2', '   ')),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      db.categoriesDao.create(name: 'santé', icon: 'x', color: 1),
      throwsA(isA<ValidationException>()),
    );
    await db.close();
  });

  test('supprimer une catégorie déplace ses documents', () async {
    final db = AppDatabase.openEncrypted(file, key);
    final cat = await db.categoriesDao.create(
      name: 'Voiture',
      icon: 'directions_car',
      color: CategoryColors.reference['red']!,
    );
    expect(cat.nameKey, 'voiture');
    expect(cat.sortOrder, 7);
    await db.documentsDao.insertDocument(doc('a1', 'Carte grise', category: cat.id));

    await db.categoriesDao.deleteMovingDocuments(cat.id);
    expect((await db.documentsDao.getById('a1'))!.categoryId, DefaultCategory.othersId);
    expect(await db.categoriesDao.getById(cat.id), isNull);

    await expectLater(
      db.categoriesDao.deleteMovingDocuments(DefaultCategory.othersId),
      throwsA(isA<ValidationException>()),
    );
    final counts = await db.categoriesDao.watchWithCounts().first;
    expect(counts.last.category.id, DefaultCategory.othersId);
    expect(counts.last.documentCount, 1);
    await db.close();
  });

  test('dates seules et réglages JSON', () async {
    final db = AppDatabase.openEncrypted(file, key);
    await db.documentsDao.insertDocument(
      doc('a1', 'Visa', expiration: const DateOnly(2027, 2, 14)),
    );
    final row = (await db.documentsDao.getById('a1'))!;
    expect(row.expirationDate, const DateOnly(2027, 2, 14));
    expect(row.issueDate, isNull);

    await db.settingsDao.writeConfig('reminder_time', '08:30');
    await db.settingsDao.setAutoLock(const Duration(minutes: 5));
    expect(await db.settingsDao.readConfig('reminder_time'), '08:30');
    expect((await db.settingsDao.get()).autoLockDuration, 300);
    await db.close();
  });

  test('DateOnly et clés de nom', () {
    expect(DateOnly.tryParse('2027-02-14'), const DateOnly(2027, 2, 14));
    expect(DateOnly.tryParse('2027-02-30'), isNull);
    expect(DateOnly.tryParse('14/02/2027'), isNull);
    expect(const DateOnly(2027, 2, 14).toIso(), '2027-02-14');
    expect(const DateOnly(2027, 3, 1).daysFrom(const DateOnly(2027, 2, 14)), 15);
    expect(const DateOnly(2026, 12, 31).addDays(1), const DateOnly(2027, 1, 1));
    expect(TextNormalizer.nameKey('  Santé  '), 'sante');
    expect(TextNormalizer.nameKey('Études   Supérieures'), 'etudes superieures');
    expect(TextNormalizer.nameKey('Œuvre'), 'oeuvre');
  });

  test('base en mémoire pour les tests', () async {
    final db = AppDatabase.inMemory();
    expect((await db.categoriesDao.getAll()).length, 7);
    await db.close();
  });
}
