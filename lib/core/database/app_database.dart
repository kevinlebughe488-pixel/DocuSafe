import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../config/app_config.dart';
import '../errors/app_exception.dart';
import '../utils/bytes.dart';
import '../utils/date_only.dart';
import '../utils/text_normalizer.dart';
import 'daos/categories_dao.dart';
import 'daos/documents_dao.dart';
import 'daos/settings_dao.dart';
import 'default_categories.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// Base de données chiffrée de DocuSafe (docs/03-modele-de-donnees.md).
///
/// Elle n'est ouverte que lorsque le coffre est déverrouillé, avec une clé
/// dérivée de la clé du coffre. Le moteur est SQLite3MultipleCiphers
/// (ChaCha20-Poly1305) : chaque page du fichier est chiffrée, journal compris.
@DriftDatabase(
  tables: [Categories, Documents, Tags, DocumentTags, Reminders, VaultSettings],
  daos: [CategoriesDao, DocumentsDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Ouvre (ou crée) la base chiffrée [file] avec [key] (32 octets).
  ///
  /// Lève [CryptoException.integrity] si la clé est fausse et
  /// [StorageException] si le moteur chiffré n'est pas disponible.
  factory AppDatabase.openEncrypted(File file, Uint8List key) {
    if (key.length != 32) {
      throw ArgumentError.value(key.length, 'key', '32 octets attendus');
    }
    final hexKey = Bytes.toHex(key);
    return AppDatabase(
      NativeDatabase.createInBackground(
        file,
        setup: (db) => applyEncryptionKey(db, hexKey),
      ),
    );
  }

  /// Base en mémoire, pour les tests : pas de chiffrement.
  factory AppDatabase.inMemory() => AppDatabase(NativeDatabase.memory());

  /// Applique la clé et vérifie qu'elle ouvre bien la base.
  ///
  /// Fonction de niveau supérieur : elle s'exécute dans l'isolate de la base.
  static void applyEncryptionKey(sqlite.Database db, String hexKey) {
    // Sur un SQLite ordinaire, ce PRAGMA ne renvoie rien : on refuse alors
    // d'ouvrir, pour ne jamais écrire une base en clair. (Un simple SELECT
    // échouerait ici, car le schéma ne peut pas être lu avant la clé.)
    if (db.select('PRAGMA cipher').isEmpty) {
      throw const StorageException('database.cipher_unavailable');
    }
    // Clé brute de 32 octets (hexadécimal), schéma ChaCha20-Poly1305.
    db.execute("PRAGMA key = \"x'$hexKey'\"");
    try {
      db.select('SELECT count(*) FROM sqlite_master');
    } on sqlite.SqliteException {
      throw CryptoException.integrity;
    }
    db.execute('PRAGMA secure_delete = ON');
  }

  /// Force l'ouverture réelle de la base (clé vérifiée, migrations faites).
  ///
  /// Les erreurs venant de l'isolate de la base sont « déballées » : une
  /// mauvaise clé lève [CryptoException.integrity], un moteur absent
  /// [StorageException]. En cas d'échec, la base est fermée.
  Future<void> ensureOpened() async {
    try {
      await settingsDao.get();
    } on DriftRemoteException catch (e) {
      await close();
      final cause = e.remoteCause;
      if (cause is AppException) {
        throw cause;
      }
      throw StorageException('database.open', cause: cause);
    } on Object {
      await close();
      rethrow;
    }
  }

  @override
  int get schemaVersion => AppConfig.databaseSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createSearchIndex();
      await _createIndexes();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      if (details.wasCreated) {
        await _seed();
      }
    },
  );

  /// Index de recherche FTS5 : une ligne par document, mise à jour dans la
  /// même transaction que le document (voir [DocumentsDao]).
  Future<void> _createSearchIndex() => customStatement('''
    CREATE VIRTUAL TABLE documents_fts USING fts5(
      document_id UNINDEXED,
      title, doc_type, description, tags, file_name, content,
      tokenize = 'unicode61 remove_diacritics 2'
    )
  ''');

  Future<void> _createIndexes() async {
    const statements = [
      'CREATE INDEX idx_documents_category ON documents (category_id)',
      'CREATE INDEX idx_documents_created ON documents (created_at)',
      'CREATE INDEX idx_documents_opened ON documents (last_opened_at)',
      'CREATE INDEX idx_documents_expiration ON documents (expiration_date)',
      'CREATE INDEX idx_documents_favorite ON documents (is_favorite)',
      'CREATE INDEX idx_documents_hash ON documents (integrity_hash)',
      'CREATE INDEX idx_reminders_date ON reminders (reminder_date)',
      'CREATE INDEX idx_document_tags_tag ON document_tags (tag_id)',
    ];
    for (final s in statements) {
      await customStatement(s);
    }
  }

  /// Réglages par défaut et catégories initiales.
  Future<void> _seed() async {
    await transaction(() async {
      await into(vaultSettings).insert(
        const VaultSettingsCompanion(id: Value(1)),
      );
      final now = DateTime.now();
      for (final c in DefaultCategory.all) {
        await into(categories).insert(
          CategoriesCompanion.insert(
            id: c.id,
            name: c.name,
            nameKey: TextNormalizer.nameKey(c.name),
            icon: c.icon,
            color: CategoryColors.reference[c.colorKey]!,
            createdAt: now,
            sortOrder: Value(c.sortOrder),
            isSystem: Value(c.isSystem),
          ),
        );
      }
    });
  }
}
