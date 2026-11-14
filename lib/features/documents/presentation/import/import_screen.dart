import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/l10n/generated/app_localizations.dart';
import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/ds_colors.dart';
import '../../../../core/documents/ingest_document.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/utils/formats.dart';
import '../../../../core/widgets/bottom_actions.dart';
import 'import_view_model.dart';

/// Importation (écran 10) : choix de la source, liste des fichiers
/// vérifiés (acceptés, doublons, refusés), puis « Continuer ».
final class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key, this.initialSource});

  /// Source à ouvrir immédiatement (depuis le bouton « + »).
  final ImportSource? initialSource;

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

final class _ImportScreenState extends ConsumerState<ImportScreen> {
  @override
  void initState() {
    super.initState();
    final source = widget.initialSource;
    if (source != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_pick(source)));
    }
  }

  Future<void> _pick(ImportSource source) async {
    final controller = ref.read(vaultControllerProvider.notifier);
    // Le sélecteur fait passer l'application en arrière-plan : tolérance.
    controller.beginExternalOperation();
    try {
      await ref.read(importViewModelProvider.notifier).pick(source);
    } finally {
      controller.endExternalOperation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(importViewModelProvider);
    final vm = ref.read(importViewModelProvider.notifier);
    final selectedCount = state.selected.length;
    final busy = state.isChecking;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          vm.reset();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.importTitle)),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenMargin),
              child: Row(
                children: [
                  Expanded(
                    child: _SourceCard(
                      icon: Icons.file_open_outlined,
                      title: l10n.importSourceFiles,
                      subtitle: l10n.importSourceFilesSub,
                      onTap: busy ? null : () => _pick(ImportSource.files),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _SourceCard(
                      icon: Icons.photo_library_outlined,
                      title: l10n.importSourceGallery,
                      subtitle: l10n.importSourceGallerySub,
                      onTap: busy ? null : () => _pick(ImportSource.gallery),
                    ),
                  ),
                ],
              ),
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
                child: Text(
                  ErrorMessages.of(l10n, state.error!),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            if (state.items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenMargin,
                  AppSpacing.sm,
                  AppSpacing.screenMargin,
                  AppSpacing.xs,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.importSelected(state.items.length),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                children: [
                  for (final item in state.items)
                    _ItemTile(
                      item: item,
                      onRemove: () => vm.remove(item.id),
                      onIncludeDuplicate: (v) => vm.setIncludeDuplicate(item.id, v),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
              child: Text(
                l10n.importFormats,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            BottomActions(
              children: [
                LargeFilledButton(
                  label: l10n.importContinue(selectedCount),
                  onPressed: selectedCount == 0 || busy
                      ? null
                      : () {
                          vm.prepareForms();
                          unawaited(context.push(Routes.documentsImportInfo));
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.categoryIcon),
                ),
                child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: theme.textTheme.titleMedium),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.onRemove,
    required this.onIncludeDuplicate,
  });

  final ImportItem item;
  final VoidCallback onRemove;
  final ValueChanged<bool> onIncludeDuplicate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ds = context.dsColors;
    final accepted = item.accepted;
    final rejected = item.rejected;

    Widget leading;
    final thumb = accepted?.preview.thumbnailJpeg;
    if (thumb != null) {
      leading = ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(thumb, width: 48, height: 64, fit: BoxFit.cover),
      );
    } else {
      leading = Container(
        width: 48,
        height: 64,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          rejected != null ? Icons.insert_drive_file_outlined : Icons.description_outlined,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final String subtitle;
    Color? subtitleColor;
    Widget trailing;
    if (item.isChecking) {
      subtitle = l10n.importChecking;
      trailing = const SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator.adaptive(strokeWidth: 2),
      );
    } else if (rejected != null) {
      subtitle = switch (rejected.reason) {
        FileRejectReason.unsupportedFormat => l10n.importUnsupported,
        FileRejectReason.tooLarge => l10n.importTooLarge,
        FileRejectReason.unreadable => l10n.importUnreadable,
        FileRejectReason.empty => l10n.importEmpty,
      };
      subtitleColor = theme.colorScheme.error;
      trailing = Icon(Icons.error_rounded, color: theme.colorScheme.error);
    } else if (accepted!.isDuplicate) {
      subtitle = l10n.importDuplicate;
      subtitleColor = ds.warning;
      trailing = Checkbox.adaptive(
        value: item.includeDuplicate,
        onChanged: (v) => onIncludeDuplicate(v ?? false),
        semanticLabel: l10n.importIncludeDuplicate,
      );
    } else {
      subtitle = '${accepted.format.label} · ${Formats.fileSize(accepted.size)}';
      trailing = Icon(Icons.check_circle_rounded, color: ds.success);
    }

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: ColoredBox(
        color: theme.colorScheme.errorContainer,
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.onErrorContainer),
          ),
        ),
      ),
      child: ListTile(
        leading: leading,
        title: Text(item.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          accepted != null && accepted.isDuplicate && item.includeDuplicate
              ? '$subtitle · ${l10n.importIncludeDuplicate}'
              : subtitle,
          style: TextStyle(color: subtitleColor),
        ),
        trailing: trailing,
      ),
    );
  }
}
