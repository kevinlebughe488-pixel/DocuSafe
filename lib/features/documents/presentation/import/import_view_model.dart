import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../../core/database/app_database.dart';
import '../../../../core/database/default_categories.dart';
import '../../../../core/documents/ingest_document.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/platform/file_picker_service.dart';
import '../../../../core/platform/thumbnail_service.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/app_log.dart';
import '../../../../core/utils/secure_random.dart';
import '../edit/document_form.dart';

enum ImportSource { files, gallery }

/// Un fichier choisi, en cours de vérification ou vérifié.
final class ImportItem {
  const ImportItem({
    required this.id,
    required this.displayName,
    required this.file,
    this.title,
    this.check,
    this.includeDuplicate = false,
    this.form,
  });

  final String id;
  final String displayName;

  /// Copie dans le dossier temporaire privé.
  final File file;

  /// Titre proposé (scan : « Scan du 14/11/2026 »), sinon le nom du fichier.
  final String? title;
  final FileCheck? check;

  /// Doublon que l'utilisateur veut importer quand même.
  final bool includeDuplicate;

  /// Informations saisies (étape « Informations »).
  final DocumentFormValue? form;

  bool get isChecking => check == null;
  FileAccepted? get accepted => check is FileAccepted ? check! as FileAccepted : null;
  FileRejected? get rejected => check is FileRejected ? check! as FileRejected : null;

  /// Retenu pour l'enregistrement.
  bool get isSelected {
    final a = accepted;
    return a != null && (!a.isDuplicate || includeDuplicate);
  }

  String get defaultTitle => title ?? p.basenameWithoutExtension(displayName);

  ImportItem copyWith({
    FileCheck? check,
    bool? includeDuplicate,
    DocumentFormValue? form,
  }) => ImportItem(
    id: id,
    displayName: displayName,
    file: file,
    title: title,
    check: check ?? this.check,
    includeDuplicate: includeDuplicate ?? this.includeDuplicate,
    form: form ?? this.form,
  );
}

enum ImportPhase { picking, checking, ready, saving, done }

/// Résultat d'un enregistrement.
final class ImportProgress {
  const ImportProgress({
    required this.current,
    required this.total,
    this.stage,
  });

  final int current;
  final int total;
  final IngestStage? stage;
}

final class ImportState {
  const ImportState({
    this.phase = ImportPhase.picking,
    this.items = const [],
    this.commonCategoryId,
    this.progress,
    this.savedCount = 0,
    this.failedCount = 0,
    this.error,
  });

  final ImportPhase phase;
  final List<ImportItem> items;

  /// Catégorie commune (plusieurs fichiers).
  final String? commonCategoryId;
  final ImportProgress? progress;
  final int savedCount;
  final int failedCount;
  final Object? error;

  List<ImportItem> get selected => items.where((i) => i.isSelected).toList();
  bool get isChecking => items.any((i) => i.isChecking);

  ImportState copyWith({
    ImportPhase? phase,
    List<ImportItem>? items,
    String? commonCategoryId,
    ImportProgress? progress,
    bool clearProgress = false,
    int? savedCount,
    int? failedCount,
    Object? error,
    bool clearError = false,
  }) => ImportState(
    phase: phase ?? this.phase,
    items: items ?? this.items,
    commonCategoryId: commonCategoryId ?? this.commonCategoryId,
    progress: clearProgress ? null : (progress ?? this.progress),
    savedCount: savedCount ?? this.savedCount,
    failedCount: failedCount ?? this.failedCount,
    error: clearError ? null : (error ?? this.error),
  );
}

/// ViewModel de l'importation (docs/05-parcours-utilisateurs.md §4).
final class ImportViewModel extends Notifier<ImportState> {
  @override
  ImportState build() => const ImportState();

  void reset() {
    _cleanupFiles(state.items);
    state = const ImportState();
  }

  /// Ouvre le sélecteur, copie les fichiers dans le dossier temporaire privé
  /// puis les vérifie un par un.
  Future<void> pick(ImportSource source) async {
    final picker = ref.read(filePickerServiceProvider);
    final List<PickedFile> picked;
    try {
      picked = switch (source) {
        ImportSource.files => await picker.pickDocuments(),
        ImportSource.gallery => await picker.pickPhotos(),
      };
    } on AppException catch (e) {
      state = state.copyWith(error: e);
      return;
    }
    if (picked.isEmpty) {
      return;
    }
    final paths = ref.read(vaultPathsProvider);
    await paths.secureTempDir.create(recursive: true);
    final newItems = <ImportItem>[];
    for (final f in picked) {
      final id = SecureRandom.uuid();
      final ext = p.extension(f.displayName);
      final dest = File(p.join(paths.secureTempDir.path, '$id$ext'));
      try {
        await f.file.copy(dest.path);
        // La copie faite par le sélecteur n'a plus d'utilité.
        if (p.isWithin(Directory.systemTemp.path, f.file.path) ||
            !p.isWithin(paths.secureTempDir.path, f.file.path)) {
          await _deleteQuietly(f.file);
        }
      } on FileSystemException catch (e, s) {
        AppLog.error('import.copy', e, s);
        continue;
      }
      newItems.add(ImportItem(id: id, displayName: f.displayName, file: dest));
    }
    await picker.clearTemporaryFiles();
    state = state.copyWith(
      phase: ImportPhase.checking,
      items: [...state.items, ...newItems],
      clearError: true,
    );
    final ingest = ref.read(ingestDocumentProvider);
    for (final item in newItems) {
      final check = await ingest.check(item.file);
      _replace(item.copyWith(check: check));
    }
    state = state.copyWith(phase: ImportPhase.ready);
  }

  /// PDF issu du scanner : même suite que l'importation (vérification,
  /// informations, enregistrement). [preview] remplace l'aperçu calculé
  /// (miniature de la première page, nombre de pages).
  Future<bool> addScannedPdf({
    required File pdf,
    required String displayName,
    required String title,
    FilePreview? preview,
  }) async {
    _cleanupFiles(state.items);
    final item = ImportItem(
      id: SecureRandom.uuid(),
      displayName: displayName,
      file: pdf,
      title: title,
    );
    state = ImportState(phase: ImportPhase.checking, items: [item]);
    var check = await ref.read(ingestDocumentProvider).check(pdf);
    if (check is FileAccepted && preview != null) {
      check = check.withPreview(preview);
    }
    _replace(item.copyWith(check: check, includeDuplicate: true));
    state = state.copyWith(phase: ImportPhase.ready);
    prepareForms();
    return check is FileAccepted;
  }

  void setIncludeDuplicate(String id, bool include) {
    final item = state.items.firstWhere((i) => i.id == id);
    _replace(item.copyWith(includeDuplicate: include));
  }

  Future<void> remove(String id) async {
    final item = state.items.firstWhere((i) => i.id == id);
    await _deleteQuietly(item.file);
    state = state.copyWith(items: state.items.where((i) => i.id != id).toList());
  }

  /// Prépare l'étape « Informations » : un formulaire par fichier retenu.
  void prepareForms() {
    final selected = state.selected;
    final defaultCategory = state.commonCategoryId ?? DefaultCategory.othersId;
    state = state.copyWith(
      commonCategoryId: defaultCategory,
      items: [
        for (final item in state.items)
          if (item.isSelected)
            item.copyWith(
              form:
                  item.form ??
                  DocumentFormValue(
                    title: item.defaultTitle,
                    categoryId: defaultCategory,
                  ),
            )
          else
            item,
      ],
    );
    if (selected.length == 1) {
      return;
    }
  }

  void setForm(String id, DocumentFormValue form) {
    final item = state.items.firstWhere((i) => i.id == id);
    _replace(item.copyWith(form: form));
  }

  /// Catégorie commune à tous les fichiers retenus.
  void setCommonCategory(String categoryId) {
    state = state.copyWith(
      commonCategoryId: categoryId,
      items: [
        for (final item in state.items)
          if (item.form != null)
            item.copyWith(form: item.form!.copyWith(categoryId: categoryId))
          else
            item,
      ],
    );
  }

  /// Enregistre tous les fichiers retenus, l'un après l'autre.
  Future<void> save() async {
    final selected = state.selected;
    if (selected.isEmpty) {
      return;
    }
    final ingest = ref.read(ingestDocumentProvider);
    var saved = 0;
    var failed = 0;
    state = state.copyWith(
      phase: ImportPhase.saving,
      progress: ImportProgress(current: 1, total: selected.length),
      clearError: true,
    );
    for (var i = 0; i < selected.length; i++) {
      final item = selected[i];
      final form = item.form ?? DocumentFormValue(title: item.defaultTitle);
      try {
        await ingest(
          IngestRequest(
            source: item.file,
            fileName: item.displayName,
            check: item.accepted!,
            title: form.title.trim().isEmpty ? item.defaultTitle : form.title,
            categoryId: form.categoryId ?? state.commonCategoryId ?? DefaultCategory.othersId,
            docType: form.docType,
            description: form.description,
            issueDate: form.issueDate,
            expirationDate: form.expirationDate,
            tags: form.tags,
          ),
          onStage: (stage) => state = state.copyWith(
            progress: ImportProgress(
              current: i + 1,
              total: selected.length,
              stage: stage,
            ),
          ),
        );
        saved++;
      } on Object catch (e, s) {
        AppLog.error('import.save', e, s);
        failed++;
      }
    }
    // Les fichiers non retenus (refusés, doublons ignorés) sont supprimés.
    _cleanupFiles(state.items.where((i) => !i.isSelected));
    state = state.copyWith(
      phase: ImportPhase.done,
      savedCount: saved,
      failedCount: failed,
      clearProgress: true,
    );
  }

  void _replace(ImportItem item) {
    state = state.copyWith(
      items: [for (final i in state.items) i.id == item.id ? item : i],
    );
  }

  static void _cleanupFiles(Iterable<ImportItem> items) {
    for (final item in items) {
      unawaited(_deleteQuietly(item.file));
    }
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException catch (e, s) {
      AppLog.error('import.cleanup', e, s);
    }
  }
}

final importViewModelProvider = NotifierProvider<ImportViewModel, ImportState>(
  ImportViewModel.new,
);

/// Catégories pour les formulaires.
final importCategoriesProvider = FutureProvider.autoDispose<List<CategoryRow>>(
  (ref) => ref.watch(databaseProvider).categoriesDao.getAll(),
);
