import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/l10n/generated/app_localizations.dart';
import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/database/tables.dart';
import '../../../../core/documents/document_repository.dart';
import '../../../../core/documents/file_formats.dart';
import '../../../../core/providers.dart';
import '../../../../core/security/lock/vault_state.dart';
import '../../../../core/utils/date_only.dart';
import '../../../../core/utils/formats.dart';
import '../../../../core/widgets/category_icon.dart';
import '../../../../core/widgets/document_thumbnail.dart';
import '../../../../core/widgets/secure_label.dart';
import '../../../../core/widgets/state_view.dart';
import '../../../../core/widgets/status_badge.dart';
import '../list/documents_view_model.dart';
import '../share/document_exit_flow.dart';

/// Fiche d'un document (écran 7) : aperçu, informations, actions.
final class DocumentDetailScreen extends ConsumerWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(documentDetailProvider(documentId));
    return switch (detail) {
      AsyncData(value: final d?) => _Detail(detail: d),
      AsyncData() => Scaffold(
        appBar: AppBar(),
        body: StateView(
          icon: Icons.search_off_rounded,
          title: l10n.detailNotFound,
          body: '',
        ),
      ),
      AsyncError() => Scaffold(
        appBar: AppBar(),
        body: StateView(
          icon: Icons.error_outline_rounded,
          title: l10n.commonErrorTitle,
          body: l10n.commonErrorBody,
          isError: true,
        ),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      ),
    };
  }
}

enum _Action { edit, move, delete }

final class _Detail extends ConsumerWidget {
  const _Detail({required this.detail});

  final DocumentDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final doc = detail.document;
    final repo = ref.read(documentRepositoryProvider);
    final expiration = doc.expirationDate;
    final sizeLabel = [
      doc.fileType.format.label,
      Formats.fileSize(doc.fileSize),
      if (doc.pageCount != null && doc.fileType == DocumentFileType.pdf)
        l10n.pageCount(doc.pageCount!),
    ].join(' · ');

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: doc.isFavorite
                ? l10n.documentFavoriteRemove
                : l10n.documentFavoriteAdd,
            icon: Icon(
              doc.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: doc.isFavorite ? theme.colorScheme.primary : null,
            ),
            onPressed: () => repo.setFavorite(doc.id, !doc.isFavorite),
          ),
          PopupMenuButton<_Action>(
            onSelected: (a) => _onAction(context, ref, a),
            itemBuilder: (_) => [
              PopupMenuItem(value: _Action.edit, child: Text(l10n.detailEdit)),
              PopupMenuItem(value: _Action.move, child: Text(l10n.detailMove)),
              PopupMenuItem(
                value: _Action.delete,
                child: Text(
                  l10n.detailDelete,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          ColoredBox(
            color: theme.colorScheme.surfaceContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Stack(
                  children: [
                    DocumentThumbnail(document: doc, size: ThumbnailSize.xl),
                    if (doc.pageCount != null &&
                        doc.fileType == DocumentFileType.pdf)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: StatusBadge(
                          label: l10n.pageCount(doc.pageCount!),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    ActionChip(
                      avatar: CategoryIcon(
                        icon: detail.category.icon,
                        color: detail.category.color,
                        size: 24,
                      ),
                      label: Text(detail.category.name),
                      onPressed: () => context.go(
                        Routes.documentsOfCategory(detail.category.id),
                      ),
                    ),
                    Chip(
                      avatar: Icon(
                        doc.fileType == DocumentFileType.pdf
                            ? Icons.picture_as_pdf_outlined
                            : Icons.image_outlined,
                        size: 18,
                      ),
                      label: Text(sizeLabel),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: _actionStyle,
                        onPressed: () =>
                            context.push(Routes.documentView(doc.id)),
                        icon: const Icon(Icons.description_outlined),
                        label: Text(l10n.detailOpen),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        style: _actionStyle,
                        onPressed: () => runDocumentExit(
                          context,
                          ref,
                          doc,
                          DocumentExit.share,
                        ),
                        icon: const Icon(Icons.share_outlined),
                        label: Text(l10n.detailShare),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        style: _actionStyle,
                        onPressed: () => runDocumentExit(
                          context,
                          ref,
                          doc,
                          DocumentExit.export,
                        ),
                        icon: const Icon(Icons.download_outlined),
                        label: Text(l10n.detailExport),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (expiration != null)
            InkWell(
              onTap: () => context.push(Routes.documentReminders(doc.id)),
              child: _KeyValueRow(
                label: l10n.detailExpiration,
                value: Formats.date(expiration),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusBadge.expiry(
                      ExpiryInfo.of(l10n, expiration, DateOnly.today()),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          if (doc.issueDate != null)
            _KeyValueRow(
              label: l10n.detailIssue,
              value: Formats.date(doc.issueDate!),
            ),
          if (doc.docType != null)
            _KeyValueRow(label: l10n.detailType, value: doc.docType!),
          if (detail.tags.isNotEmpty)
            _KeyValueRow(
              label: l10n.detailTags,
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final t in detail.tags)
                    Chip(
                      label: Text(t.name),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          _KeyValueRow(
            label: l10n.detailAddedOn,
            value: Formats.dateTime(doc.createdAt),
          ),
          if (doc.updatedAt.difference(doc.createdAt).inMinutes.abs() >= 1)
            _KeyValueRow(
              label: l10n.detailUpdatedOn,
              value: Formats.dateTime(doc.updatedAt),
            ),
          _KeyValueRow(label: l10n.detailFile, value: doc.fileName),
          if (doc.description != null)
            _KeyValueRow(
              label: l10n.detailDescription,
              value: doc.description!,
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenMargin,
              AppSpacing.md,
              AppSpacing.screenMargin,
              0,
            ),
            child: SecureLabel(),
          ),
        ],
      ),
    );
  }

  static final _actionStyle = FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(AppSpacing.touchTarget),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
  );

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    _Action action,
  ) async {
    final doc = detail.document;
    switch (action) {
      case _Action.edit:
        await context.push(Routes.documentEdit(doc.id));
      case _Action.delete:
        await context.push(Routes.documentDelete(doc.id));
      case _Action.move:
        final l10n = AppLocalizations.of(context);
        final categories =
            ref.read(categoriesByIdProvider).value?.values.toList() ?? [];
        final target = await showModalBottomSheet<String>(
          context: context,
          builder: (ctx) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    l10n.detailMoveTitle,
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                ),
                for (final c in categories)
                  ListTile(
                    leading: CategoryIcon(icon: c.icon, color: c.color),
                    title: Text(c.name),
                    trailing: c.id == doc.categoryId
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () => Navigator.of(ctx).pop(c.id),
                  ),
              ],
            ),
          ),
        );
        if (target != null && target != doc.categoryId) {
          await ref
              .read(documentRepositoryProvider)
              .moveToCategory(doc.id, target);
        }
    }
  }
}

final class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({
    required this.label,
    this.value,
    this.child,
    this.trailing,
  });

  final String label;
  final String? value;
  final Widget? child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenMargin,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: child ?? Text(value ?? '', style: theme.textTheme.bodyLarge),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Fiche observée : se met à jour à chaque changement.
final documentDetailProvider = StreamProvider.autoDispose
    .family<DocumentDetail?, String>((ref, id) {
      if (ref.watch(vaultControllerProvider) is! VaultUnlocked) {
        return const Stream.empty();
      }
      return ref.watch(documentRepositoryProvider).watchDetail(id);
    });
