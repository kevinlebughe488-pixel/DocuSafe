import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/router/routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/bottom_actions.dart';
import 'scan_view_model.dart';

/// Aperçu du scan (écran 9) : réorganiser par glisser-déposer, retirer une
/// page, en ajouter, ou tout recommencer, puis « Continuer ».
final class ScanPreviewScreen extends ConsumerWidget {
  const ScanPreviewScreen({super.key});

  Future<bool> _confirmDiscard(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: Text(l10n.scanDiscardTitle),
        content: Text(l10n.scanDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.scanDiscard),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(scanViewModelProvider);
    final vm = ref.read(scanViewModelProvider.notifier);
    final pages = state.pages;
    final busy = state.scanning || state.building;

    Future<void> close() async {
      if (pages.isEmpty || await _confirmDiscard(context)) {
        await vm.discard();
        if (context.mounted) {
          context.pop();
        }
      }
    }

    Future<void> next() async {
      final now = DateTime.now();
      final title = l10n.scanDefaultTitle(DateFormat('dd/MM/yyyy', 'fr').format(now));
      final fileName = 'Scan du ${DateFormat('dd-MM-yyyy', 'fr').format(now)}.pdf';
      final ok = await vm.buildAndHandOff(title: title, fileName: fileName);
      if (ok && context.mounted) {
        context.pushReplacement(Routes.documentsImportInfo);
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !busy) {
          unawaited(close());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: l10n.commonClose,
            icon: const Icon(Icons.close_rounded),
            onPressed: busy ? null : close,
          ),
          title: Text(l10n.scanPreviewTitle),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                AppSpacing.sm,
                AppSpacing.screenMargin,
                AppSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.scanPreviewHint(pages.length),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
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
            Expanded(
              child: state.building
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator.adaptive(),
                          const SizedBox(height: AppSpacing.lg),
                          Text(l10n.scanBuilding),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      itemCount: pages.length + 1,
                      onReorderItem: (from, to) {
                        if (from < pages.length && to < pages.length) {
                          vm.reorder(from, to);
                        }
                      },
                      itemBuilder: (context, i) {
                        if (i == pages.length) {
                          return Padding(
                            key: const ValueKey('add'),
                            padding: const EdgeInsets.all(AppSpacing.screenMargin),
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(AppSpacing.largeButtonHeight),
                              ),
                              onPressed: busy ? null : vm.scan,
                              icon: const Icon(Icons.add_a_photo_outlined),
                              label: Text(l10n.scanAddPages),
                            ),
                          );
                        }
                        return _PageTile(
                          key: ValueKey(pages[i].id),
                          page: pages[i],
                          number: i + 1,
                          index: i,
                          onRemove: busy ? null : () => vm.remove(pages[i].id),
                        );
                      },
                    ),
            ),
            BottomActions(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(AppSpacing.largeButtonHeight),
                        ),
                        onPressed: busy ? null : vm.restart,
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: Text(l10n.scanRestart),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(AppSpacing.largeButtonHeight),
                        ),
                        onPressed: busy || pages.isEmpty ? null : next,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(l10n.scanContinue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _PageTile extends StatelessWidget {
  const _PageTile({
    super.key,
    required this.page,
    required this.number,
    required this.index,
    required this.onRemove,
  });

  final ScannedPage page;
  final int number;
  final int index;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenMargin,
        vertical: AppSpacing.xs,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 96,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Image.file(
                  page.file,
                  fit: BoxFit.cover,
                  cacheWidth: 216,
                  semanticLabel: l10n.scanPageLabel(number),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(l10n.scanPageLabel(number), style: theme.textTheme.titleMedium),
              ),
              IconButton(
                tooltip: l10n.scanRemovePage(number),
                icon: const Icon(Icons.close_rounded),
                onPressed: onRemove,
              ),
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: Icon(Icons.drag_indicator_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
