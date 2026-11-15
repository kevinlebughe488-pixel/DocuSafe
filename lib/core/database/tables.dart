import 'package:drift/drift.dart';

import '../utils/date_only.dart';

/// Tables de la base chiffrée (docs/03-modele-de-donnees.md).
///
/// Les dates-heures sont des instants (époque Unix, UTC). Les dates seules
/// sont du texte `AAAA-MM-JJ` converti en [DateOnly].

/// Formats de fichier acceptés.
enum DocumentFileType { pdf, jpeg, png }

class DateOnlyConverter extends TypeConverter<DateOnly, String> {
  const DateOnlyConverter();

  @override
  DateOnly fromSql(String fromDb) =>
      DateOnly.tryParse(fromDb) ?? const DateOnly(1970, 1, 1);

  @override
  String toSql(DateOnly value) => value.toIso();
}

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 40)();

  /// Nom simplifié (minuscules, sans accents), unique : pas de doublon.
  TextColumn get nameKey => text().unique()();
  TextColumn get icon => text()();
  IntColumn get color => integer()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Vrai pour « Autres », qui ne peut pas être supprimée.
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('DocumentRow')
class Documents extends Table {
  TextColumn get id => text()();
  // ignore: recursive_getters
  TextColumn get title => text()
      .withLength(min: 1, max: 200)
      // ignore: recursive_getters
      .check(title.trim().length.isBiggerThanValue(0))();
  TextColumn get docType => text().nullable()();

  /// La suppression d'une catégorie est refusée tant qu'elle a des documents.
  TextColumn get categoryId =>
      text().references(Categories, #id, onDelete: KeyAction.restrict)();
  TextColumn get fileName => text()();

  /// Chemin relatif au dossier du coffre.
  TextColumn get encryptedFilePath => text().unique()();
  TextColumn get fileType => textEnum<DocumentFileType>()();
  IntColumn get fileSize =>
      // ignore: recursive_getters
      integer().check(fileSize.isBiggerOrEqualValue(0))();
  IntColumn get pageCount => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();
  TextColumn get issueDate =>
      text().map(const DateOnlyConverter()).nullable()();
  TextColumn get expirationDate =>
      text().map(const DateOnlyConverter()).nullable()();
  TextColumn get description => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// Texte extrait par OCR (vide dans le MVP).
  TextColumn get contentIndex => text().nullable()();

  /// Empreinte SHA-256 du fichier d'origine, en hexadécimal.
  TextColumn get integrityHash => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TagRow')
class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 30)();
  TextColumn get nameKey => text().unique()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('DocumentTagRow')
class DocumentTags extends Table {
  TextColumn get documentId =>
      text().references(Documents, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {documentId, tagId};
}

@DataClassName('ReminderRow')
class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get documentId =>
      text().references(Documents, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get reminderDate => dateTime()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  /// Jours avant l'expiration (90, 30, 7, 0).
  IntColumn get offsetDays => integer()();

  /// Numéro de la notification côté système.
  IntColumn get notificationId => integer().unique()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {documentId, offsetDays},
  ];
}

@DataClassName('VaultSettingsRow')
class VaultSettings extends Table {
  IntColumn get id => integer()();
  BoolColumn get biometricEnabled =>
      boolean().withDefault(const Constant(false))();

  /// Délai de verrouillage après inactivité, en secondes.
  IntColumn get autoLockDuration => integer().withDefault(const Constant(120))();
  BoolColumn get notificationsEnabled =>
      boolean().withDefault(const Constant(true))();

  /// Autres réglages, en JSON.
  TextColumn get vaultConfiguration => text().withDefault(const Constant('{}'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
