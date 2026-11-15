import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/tables.dart';
import '../../../core/documents/file_formats.dart';
import '../../../core/documents/pdf_builder.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/platform/thumbnail_service.dart';
import '../../../core/providers.dart';
import '../../../core/utils/app_log.dart';
import '../../../core/utils/secure_random.dart';
import '../../documents/presentation/import/import_view_model.dart';

/// Une page numérisée, copiée dans le dossier temporaire privé.
final class ScannedPage {
  const ScannedPage({required this.id, required this.file});

  final String id;
  final File file;
}

final class ScanState {
  const ScanState({
    this.pages = const [],
    this.scanning = false,
    this.building = false,
    this.error,
  });

  final List<ScannedPage> pages;
  final bool scanning;
  final bool building;
  final Object? error;

  ScanState copyWith({
    List<ScannedPage>? pages,
    bool? scanning,
    bool? building,
    Object? error,
    bool clearError = true,
  }) => ScanState(
    pages: pages ?? this.pages,
    scanning: scanning ?? this.scanning,
    building: building ?? this.building,
    error: clearError ? error : (error ?? this.error),
  );
}

/// ViewModel du scanner (docs/05-parcours-utilisateurs.md §3) : pages,
/// réorganisation, ajout, retrait, recommencement, puis création du PDF.
///
/// Les images sont copiées dans `secure_tmp/` et le dossier du scanner est
/// vidé aussitôt (docs/04-securite.md §12). Le PDF suit ensuite le chemin
/// unique de l'importation (`IngestDocument`).
final class ScanViewModel extends Notifier<ScanState> {
  @override
  ScanState build() => const ScanState();

  /// Ouvre le scanner et ajoute les pages obtenues. Retourne vrai si au
  /// moins une page a été ajoutée.
  Future<bool> scan() async {
    final controller = ref.read(vaultControllerProvider.notifier);
    final scanner = ref.read(scannerServiceProvider);
    state = state.copyWith(scanning: true);
    // Le scanner fait passer l'application en arrière-plan : tolérance.
    controller.beginExternalOperation();
    try {
      final files = await scanner.scan();
      final added = await _copyToSecureTemp(files);
      state = state.copyWith(scanning: false, pages: [...state.pages, ...added]);
      return added.isNotEmpty;
    } on AppException catch (e) {
      state = state.copyWith(scanning: false, error: e);
      return false;
    } finally {
      controller.endExternalOperation();
      await scanner.cleanCache();
    }
  }

  Future<List<ScannedPage>> _copyToSecureTemp(List<File> files) async {
    final temp = ref.read(vaultPathsProvider).secureTempDir;
    await temp.create(recursive: true);
    final pages = <ScannedPage>[];
    for (final f in files) {
      final id = SecureRandom.uuid();
      try {
        final dest = await f.copy(p.join(temp.path, '$id${p.extension(f.path)}'));
        pages.add(ScannedPage(id: id, file: dest));
      } on FileSystemException catch (e, s) {
        AppLog.error('scan.copy', e, s);
      } finally {
        await _deleteQuietly(f);
      }
    }
    return pages;
  }

  void reorder(int from, int to) {
    final pages = List<ScannedPage>.from(state.pages);
    final moved = pages.removeAt(from);
    pages.insert(to, moved);
    state = state.copyWith(pages: pages);
  }

  Future<void> remove(String id) async {
    final page = state.pages.firstWhere((x) => x.id == id);
    state = state.copyWith(pages: state.pages.where((x) => x.id != id).toList());
    await _deleteQuietly(page.file);
  }

  /// Efface toutes les pages et rouvre le scanner.
  Future<bool> restart() async {
    await discard();
    return scan();
  }

  /// Abandon : efface les pages.
  Future<void> discard() async {
    final pages = state.pages;
    state = const ScanState();
    for (final page in pages) {
      await _deleteQuietly(page.file);
    }
  }

  /// Assemble les pages en PDF et le confie à l'importation. Retourne vrai
  /// si le formulaire « Informations » peut s'ouvrir.
  Future<bool> buildAndHandOff({
    required String title,
    required String fileName,
  }) async {
    final pages = state.pages;
    if (pages.isEmpty) {
      return false;
    }
    state = state.copyWith(building: true);
    final temp = ref.read(vaultPathsProvider).secureTempDir;
    final pdf = File(p.join(temp.path, '${SecureRandom.uuid()}.pdf'));
    try {
      await PdfBuilder.fromImages([for (final page in pages) page.file], pdf);
      // Miniature tirée de la première page : plus rapide et plus fiable que
      // le rendu du PDF.
      final first = pages.first.file;
      final format = await FileFormats.detectFile(first);
      final firstPreview = await ref
          .read(thumbnailServiceProvider)
          .preview(first, format?.type ?? DocumentFileType.jpeg);
      final ok = await ref
          .read(importViewModelProvider.notifier)
          .addScannedPdf(
            pdf: pdf,
            displayName: fileName,
            title: title,
            preview: FilePreview(
              thumbnailJpeg: firstPreview.thumbnailJpeg,
              pageCount: pages.length,
            ),
          );
      for (final page in pages) {
        await _deleteQuietly(page.file);
      }
      state = const ScanState();
      return ok;
    } on Object catch (e, s) {
      AppLog.error('scan.build', e, s);
      await _deleteQuietly(pdf);
      state = state.copyWith(
        building: false,
        error: e is AppException ? e : const StorageException('scan.build'),
      );
      return false;
    }
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException catch (e, s) {
      AppLog.error('scan.cleanup', e, s);
    }
  }
}

final scanViewModelProvider = NotifierProvider<ScanViewModel, ScanState>(
  ScanViewModel.new,
);
