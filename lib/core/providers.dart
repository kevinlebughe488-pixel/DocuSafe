import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'backup/backup_service.dart';
import 'database/app_database.dart';
import 'documents/delete_document.dart';
import 'documents/document_repository.dart';
import 'documents/document_search.dart';
import 'documents/export_document.dart';
import 'documents/ingest_document.dart';
import 'documents/open_document.dart';
import 'entitlements/entitlement_service.dart';
import 'errors/app_exception.dart';
import 'platform/file_picker_service.dart';
import 'platform/notification_service.dart';
import 'platform/scanner_service.dart';
import 'platform/share_intake_service.dart';
import 'platform/share_service.dart';
import 'platform/thumbnail_service.dart';
import 'reminders/reminder_service.dart';
import 'security/auth/biometric_service.dart';
import 'security/auth/pin_attempts.dart';
import 'security/crypto/crypto_engine.dart';
import 'security/crypto/dart_crypto_engine.dart';
import 'security/crypto/file_cipher.dart';
import 'security/keys/secure_store.dart';
import 'security/lock/vault_controller.dart';
import 'security/lock/vault_session.dart';
import 'security/lock/vault_state.dart';
import 'security/screen/screen_security.dart';
import 'security/vault_service.dart';
import 'storage/vault_paths.dart';

/// Providers des services partagés. Dans les tests, ils sont remplacés par
/// des versions simulées via `ProviderScope(overrides: …)`.

final cryptoEngineProvider = Provider<CryptoEngine>(
  (ref) => const DartCryptoEngine(),
);

final fileCipherProvider = Provider<FileCipher>(
  (ref) => FileCipher(ref.watch(cryptoEngineProvider)),
);

final secureStoreProvider = Provider<SecureStore>(
  (ref) => FlutterSecureStore.standard(),
);

/// Stockage protégé par biométrie forte. `null` sur les plateformes où il
/// n'existe pas ; sur Android 7 et 8 il n'est jamais lu car la biométrie n'est
/// pas proposée (voir [BiometricService]).
final biometricStoreProvider = Provider<SecureStore?>((ref) {
  if (kIsWeb) {
    return null;
  }
  return FlutterSecureStore.biometric(
    promptTitle: 'Déverrouiller DocSafe',
    promptSubtitle: 'Utilisez votre empreinte ou votre visage',
    cancelLabel: 'Utiliser mon code',
  );
});

final biometricServiceProvider = Provider<BiometricService>(
  (ref) => LocalAuthBiometricService(),
);

/// Type de biométrie forte disponible sur ce téléphone (visage, empreinte,
/// aucune). Détermine les textes et les icônes.
final biometricKindProvider = FutureProvider<BiometricKind>(
  (ref) => ref.watch(biometricServiceProvider).availableKind(),
);

final screenSecurityProvider = Provider<ScreenSecurity>(
  (ref) => const ChannelScreenSecurity(),
);

/// Horloge, remplaçable dans les tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Dossiers du coffre, résolus une fois au démarrage (voir `main.dart`).
final vaultPathsProvider = Provider<VaultPaths>(
  (ref) => throw UnimplementedError('vaultPathsProvider doit être remplacé'),
);

final vaultServiceProvider = Provider<VaultService>(
  (ref) => VaultService(
    crypto: ref.watch(cryptoEngineProvider),
    store: ref.watch(secureStoreProvider),
    biometricStore: ref.watch(biometricStoreProvider),
    paths: ref.watch(vaultPathsProvider),
    attempts: PinAttempts(ref.watch(secureStoreProvider)),
  ),
);

final vaultControllerProvider = NotifierProvider<VaultController, VaultState>(
  VaultController.new,
);

/// Base de données de la session en cours. Lève [VaultLockedException] si le
/// coffre est verrouillé : aucun écran protégé ne doit l'observer dans cet état.
final databaseProvider = Provider<AppDatabase>(
  (ref) => ref.watch(sessionProvider).database,
);

// ---------------------------------------------------------------------------
// Documents (phase 4)
// ---------------------------------------------------------------------------

final filePickerServiceProvider = Provider<FilePickerService>(
  (ref) => PlatformFilePickerService(),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => PlatformNotificationService(),
);

final reminderServiceProvider = Provider<ReminderService>(
  (ref) => ReminderService(
    database: ref.watch(databaseProvider),
    notifications: ref.watch(notificationServiceProvider),
    clock: ref.watch(clockProvider),
  ),
);

final scannerServiceProvider = Provider<ScannerService>(
  (ref) => const PlatformScannerService(),
);

final documentSearchProvider = Provider<DocumentSearch>(
  (ref) => DocumentSearch(ref.watch(databaseProvider)),
);

final thumbnailServiceProvider = Provider<ThumbnailService>(
  (ref) => const PlatformThumbnailService(),
);

/// Session déverrouillée courante. Lève [VaultLockedException] sinon.
///
/// Recalculée à chaque nouvelle session : après un verrouillage puis un
/// déverrouillage, la base, les clés et tout ce qui en dépend sont ceux de
/// la nouvelle session (l'ancienne base est fermée).
final sessionProvider = Provider<VaultSession>((ref) {
  ref.watch(
    vaultControllerProvider.select(
      (s) => s is VaultUnlocked ? s.session : null,
    ),
  );
  final controller = ref.read(vaultControllerProvider.notifier);
  return controller.session ??
      controller.lastSession ??
      (throw const VaultLockedException());
});

final documentRepositoryProvider = Provider<DocumentRepository>(
  (ref) => DocumentRepository(ref.watch(databaseProvider)),
);

final ingestDocumentProvider = Provider<IngestDocument>(
  (ref) => IngestDocument(
    session: ref.watch(sessionProvider),
    paths: ref.watch(vaultPathsProvider),
    thumbnails: ref.watch(thumbnailServiceProvider),
  ),
);

final openDocumentProvider = Provider<OpenDocument>(
  (ref) => OpenDocument(
    session: ref.watch(sessionProvider),
    paths: ref.watch(vaultPathsProvider),
  ),
);

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(paths: ref.watch(vaultPathsProvider)),
);

/// Droits d'utilisation : gratuit seulement dans le MVP (§8).
final entitlementServiceProvider = Provider<EntitlementService>(
  (ref) => const FreeEntitlementService(),
);

final shareIntakeServiceProvider = Provider<ShareIntakeService>(
  (ref) => const PlatformShareIntakeService(),
);

/// Fichiers reçus par « Partager vers DocSafe », en attente d'importation.
final pendingSharesProvider = NotifierProvider<PendingShares, List<PickedFile>>(
  PendingShares.new,
);

final class PendingShares extends Notifier<List<PickedFile>> {
  @override
  List<PickedFile> build() => const [];

  void add(List<PickedFile> files) => state = [...state, ...files];

  /// Reprend les fichiers en attente (pour l'importation) et vide la liste.
  List<PickedFile> take() {
    final files = state;
    state = const [];
    return files;
  }
}

final shareServiceProvider = Provider<ShareService>(
  (ref) => const PlatformShareService(),
);

final documentExporterProvider = Provider<DocumentExporter>(
  (ref) => DocumentExporter(
    session: ref.watch(sessionProvider),
    paths: ref.watch(vaultPathsProvider),
  ),
);

final deleteDocumentProvider = Provider<DeleteDocument>(
  (ref) => DeleteDocument(
    session: ref.watch(sessionProvider),
    paths: ref.watch(vaultPathsProvider),
  ),
);

/// Petit cache des miniatures déchiffrées, vidé au verrouillage
/// (docs/02-architecture.md §8).
final thumbnailCacheProvider = Provider<ThumbnailCache>((ref) {
  final cache = ThumbnailCache();
  ref.listen(vaultControllerProvider, (_, next) {
    if (next is! VaultUnlocked) {
      cache.clear();
    }
  });
  return cache;
});

/// Miniature déchiffrée d'un document (`null` : pas de miniature).
final thumbnailProvider = FutureProvider.autoDispose.family<Uint8List?, String>(
  (ref, documentId) async {
    final cache = ref.watch(thumbnailCacheProvider);
    final cached = cache.get(documentId);
    if (cached != null) {
      return cached.bytes;
    }
    final db = ref.watch(databaseProvider);
    final row = await db.documentsDao.getById(documentId);
    if (row == null) {
      return null;
    }
    final bytes = await ref.watch(openDocumentProvider).thumbnail(row);
    cache.put(documentId, bytes);
    return bytes;
  },
);

/// Entrée du cache : `bytes` vaut `null` quand le document n'a pas de
/// miniature (on s'en souvient aussi).
final class CachedThumbnail {
  const CachedThumbnail(this.bytes);

  final Uint8List? bytes;
}

final class ThumbnailCache {
  static const int _capacity = 60;
  final _entries = <String, CachedThumbnail>{};

  CachedThumbnail? get(String id) {
    final v = _entries.remove(id);
    if (v != null) {
      _entries[id] = v; // le plus récent en dernier
    }
    return v;
  }

  void put(String id, Uint8List? bytes) {
    _entries.remove(id);
    _entries[id] = CachedThumbnail(bytes);
    if (_entries.length > _capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  void evict(String id) => _entries.remove(id);

  void clear() => _entries.clear();
}
