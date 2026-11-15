import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/l10n/generated/app_localizations.dart';
import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/widgets/bottom_actions.dart';
import '../../../../core/widgets/document_tile.dart';
import '../../../../core/widgets/illustration_circle.dart';

/// Confirmation de suppression (écran 20) : écran dédié, « Annuler » mis en
/// avant, suppression définitive en rouge.
final class DeleteDocumentScreen extends ConsumerStatefulWidget {
  const DeleteDocumentScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<DeleteDocumentScreen> createState() => _DeleteDocumentScreenState();
}

final class _DeleteDocumentScreenState extends ConsumerState<DeleteDocumentScreen> {
  DocumentRow? _document;
  bool _busy = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final d = await ref.read(databaseProvider).documentsDao.getById(widget.documentId);
    if (mounted) {
      setState(() {
        _document = d;
        _loaded = true;
      });
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final doc = _document;
    if (doc == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(deleteDocumentProvider)(doc);
      ref.read(thumbnailCacheProvider).evict(doc.id);
      await ref.read(reminderServiceProvider).rescheduleAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.deleteDone)),
        );
        context.go(Routes.documents);
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorMessages.of(l10n, e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final doc = _document;
    return Scaffold(
      appBar: AppBar(leading: const CloseButton(), title: Text(l10n.deleteTitle)),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator.adaptive())
          : doc == null
          ? Center(child: Text(l10n.detailNotFound))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.screenMargin),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.xl),
                        const IllustrationCircle(
                          icon: Icons.delete_outline_rounded,
                          size: 120,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(l10n.deleteQuestion, style: theme.textTheme.headlineSmall),
                        const SizedBox(height: AppSpacing.lg),
                        Card(child: DocumentTile(document: doc, showFavorite: false)),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          l10n.deleteBody,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                BottomActions(
                  children: [
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(AppSpacing.largeButtonHeight),
                      ),
                      onPressed: _busy ? null : () => context.pop(),
                      child: Text(l10n.commonCancel),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(AppSpacing.largeButtonHeight),
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                      ),
                      onPressed: _busy ? null : _delete,
                      icon: const Icon(Icons.delete_rounded),
                      label: Text(l10n.deleteConfirm),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
