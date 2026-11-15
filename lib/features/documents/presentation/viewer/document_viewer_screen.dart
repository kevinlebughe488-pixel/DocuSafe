import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../app/l10n/generated/app_localizations.dart';
import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables.dart';
import '../../../../core/documents/open_document.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers.dart';
import '../../../../core/widgets/state_view.dart';
import '../share/document_exit_flow.dart';

/// Lecture d'un document (écran 7b) : toujours sur fond sombre. Le document
/// est déchiffré à ce moment-là seulement, son intégrité vérifiée ; le clair
/// est effacé à la fermeture.
final class DocumentViewerScreen extends ConsumerStatefulWidget {
  const DocumentViewerScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<DocumentViewerScreen> createState() =>
      _DocumentViewerScreenState();
}

final class _DocumentViewerScreenState
    extends ConsumerState<DocumentViewerScreen> {
  OpenedDocument? _opened;
  DocumentRow? _document;
  Object? _error;
  int _page = 1;
  int _pageCount = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    try {
      final row = await ref
          .read(databaseProvider)
          .documentsDao
          .getById(widget.documentId);
      if (row == null) {
        throw const StorageException('document.missing');
      }
      final opened = await ref.read(openDocumentProvider)(row);
      if (!mounted) {
        await opened.dispose();
        return;
      }
      setState(() {
        _document = row;
        _opened = opened;
        _pageCount = row.pageCount ?? 0;
      });
    } on Object catch (e) {
      if (mounted) {
        setState(() => _error = e);
      }
    }
  }

  @override
  void dispose() {
    unawaited(_opened?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const dark = AppColors.dark;
    return Theme(
      data: Theme.of(context)
          .copyWith(colorScheme: dark, scaffoldBackgroundColor: dark.surface),
      child: Scaffold(
        backgroundColor: dark.surface,
        appBar: AppBar(
          backgroundColor: dark.surface,
          foregroundColor: dark.onSurface,
          title: Text(_document?.title ?? ''),
          actions: [
            if (_opened != null)
              IconButton(
                tooltip: l10n.detailShare,
                icon: const Icon(Icons.share_outlined),
                onPressed: () => runDocumentExit(
                  context,
                  ref,
                  _opened!.document,
                  DocumentExit.share,
                ),
              ),
          ],
        ),
        body: _body(context, l10n),
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n) {
    final error = _error;
    if (error != null) {
      final missing = error is StorageException;
      return StateView(
        icon: Icons.broken_image_outlined,
        title: l10n.viewerCorruptTitle,
        body: missing ? l10n.viewerMissingBody : l10n.viewerCorruptBody,
        isError: true,
        actions: [
          FilledButton.tonal(
            onPressed: () => context.pushReplacement(
              Routes.documentDelete(widget.documentId),
            ),
            child: Text(l10n.viewerDeleteEntry),
          ),
        ],
      );
    }
    final opened = _opened;
    if (opened == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator.adaptive(),
            const SizedBox(height: 16),
            Text(l10n.viewerOpening),
          ],
        ),
      );
    }
    if (opened.type == DocumentFileType.pdf) {
      return Stack(
        children: [
          Positioned.fill(child: _pdf(opened)),
          if (_pageCount > 0)
            Positioned(
              right: 16,
              bottom: 16,
              child: Material(
                color: Theme.of(context).colorScheme.inverseSurface,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    l10n.viewerPage(_page, _pageCount),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onInverseSurface,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }
    return _image(opened);
  }

  Widget _pdf(OpenedDocument opened) {
    final params = PdfViewerParams(
      backgroundColor: Theme.of(context).colorScheme.surface,
      onPageChanged: (page) {
        if (page != null && mounted) {
          setState(() => _page = page);
        }
      },
      onViewerReady: (document, _) {
        if (mounted) {
          setState(() => _pageCount = document.pages.length);
        }
      },
    );
    final bytes = opened.bytes;
    if (bytes != null) {
      return PdfViewer.data(
        bytes,
        sourceName: opened.document.id,
        params: params,
      );
    }
    return PdfViewer.file(opened.tempFile!.path, params: params);
  }

  Widget _image(OpenedDocument opened) {
    final bytes = opened.bytes;
    final image = bytes != null
        ? Image.memory(bytes, fit: BoxFit.contain)
        : Image.file(opened.tempFile!, fit: BoxFit.contain);
    return InteractiveViewer(maxScale: 6, child: Center(child: image));
  }
}
