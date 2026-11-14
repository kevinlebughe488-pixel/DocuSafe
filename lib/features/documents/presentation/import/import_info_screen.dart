import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/l10n/generated/app_localizations.dart';
import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/documents/ingest_document.dart';
import '../../../../core/utils/formats.dart';
import '../../../../core/widgets/bottom_actions.dart';
import '../../../../core/widgets/category_icon.dart';
import '../../../../core/widgets/secure_label.dart';
import '../../../reminders/presentation/notification_permission.dart';
import '../edit/document_form.dart';
import 'import_view_model.dart';

/// Informations du ou des documents à enregistrer (écran 9b), puis
/// enregistrement avec progression (écran 9c).
final class ImportInfoScreen extends ConsumerStatefulWidget {
  const ImportInfoScreen({super.key});

  @override
  ConsumerState<ImportInfoScreen> createState() => _ImportInfoScreenState();
}

final class _ImportInfoScreenState extends ConsumerState<ImportInfoScreen> {
  bool _showErrors = false;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final vm = ref.read(importViewModelProvider.notifier);
    final state = ref.read(importViewModelProvider);
    if (state.selected.any((i) => !(i.form?.isValid ?? false))) {
      setState(() => _showErrors = true);
      return;
    }
    final saving = vm.save();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: _ProgressDialog(),
      ),
    );
    await saving;
    if (!mounted) {
      return;
    }
    final result = ref.read(importViewModelProvider);
    if (result.savedWithExpiration) {
      await maybeAskNotificationPermission(context, ref);
      if (!mounted) {
        return;
      }
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        content: Text(
          [
            if (result.savedCount > 0) l10n.importDone(result.savedCount),
            if (result.failedCount > 0) l10n.importFailed(result.failedCount),
            if (result.savedCount > 0) l10n.importOriginalReminder,
          ].join(' '),
        ),
      ),
    );
    vm.reset();
    context.go(Routes.documents);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(importViewModelProvider);
    final vm = ref.read(importViewModelProvider.notifier);
    final categories = ref.watch(importCategoriesProvider).value ?? const [];
    final selected = state.selected;

    ref.listen(importViewModelProvider, (prev, next) {
      // Le dialogue de progression se ferme quand l'enregistrement finit.
      if (prev?.phase == ImportPhase.saving && next.phase == ImportPhase.done) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });

    Widget body;
    if (selected.length == 1) {
      final item = selected.single;
      final form = item.form ?? DocumentFormValue(title: item.defaultTitle);
      body = DocumentForm(
        value: form,
        categories: categories,
        showTitleError: _showErrors,
        onChanged: (v) => vm.setForm(item.id, v),
        header: _FileHeader(item: item),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        children: [
          Text(
            l10n.importCommonCategory(selected.length),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            initialValue: state.commonCategoryId,
            decoration: InputDecoration(labelText: l10n.editCategory),
            items: [
              for (final c in categories)
                DropdownMenuItem(
                  value: c.id,
                  child: Row(
                    children: [
                      CategoryIcon(icon: c.icon, color: c.color, size: 28),
                      const SizedBox(width: AppSpacing.md),
                      Text(c.name),
                    ],
                  ),
                ),
            ],
            onChanged: (id) {
              if (id != null) {
                vm.setCommonCategory(id);
              }
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final item in selected) ...[
            _FileHeader(item: item),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              initialValue: item.form?.title ?? item.defaultTitle,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.editName,
                errorText: _showErrors && (item.form?.title.trim().isEmpty ?? false)
                    ? l10n.editNameRequired
                    : null,
              ),
              onChanged: (t) => vm.setForm(
                item.id,
                (item.form ?? DocumentFormValue(categoryId: state.commonCategoryId))
                    .copyWith(title: t),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.importInfoTitle)),
      body: Column(
        children: [
          Expanded(child: body),
          BottomActions(
            children: [
              LargeFilledButton(
                label: l10n.importSave,
                icon: Icons.lock_rounded,
                onPressed: selected.isEmpty || state.phase == ImportPhase.saving
                    ? null
                    : _save,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _FileHeader extends StatelessWidget {
  const _FileHeader({required this.item});

  final ImportItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accepted = item.accepted!;
    final thumb = accepted.preview.thumbnailJpeg;
    final pages = accepted.preview.pageCount;
    return Row(
      children: [
        Container(
          width: 72,
          height: 96,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: thumb != null
              ? Image.memory(thumb, fit: BoxFit.cover)
              : Icon(Icons.description_outlined, color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  if (pages != null && pages > 0) l10n.pageCount(pages),
                  accepted.format.label,
                  Formats.fileSize(accepted.size),
                ].join(' · '),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.displayName,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              _WillBeEncrypted(),
            ],
          ),
        ),
      ],
    );
  }
}

final class _WillBeEncrypted extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Icon(Icons.lock_rounded, size: 16, color: theme.colorScheme.tertiary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            l10n.importWillBeEncrypted,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.tertiary),
          ),
        ),
      ],
    );
  }
}

/// « Enregistrement… » : fichier n sur N, étape en cours.
final class _ProgressDialog extends ConsumerWidget {
  const _ProgressDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final progress = ref.watch(importViewModelProvider).progress;
    final stage = progress?.stage;
    const stages = IngestStage.values;
    final stageIndex = stage == null ? -1 : stages.indexOf(stage);
    String label(IngestStage s) => switch (s) {
      IngestStage.encrypting => l10n.importStageEncrypting,
      IngestStage.verifying => l10n.importStageVerifying,
      IngestStage.thumbnail => l10n.importStageThumbnail,
      IngestStage.saving => l10n.importStageSaving,
      IngestStage.cleaning => l10n.importStageCleaning,
    };
    final theme = Theme.of(context);
    return AlertDialog.adaptive(
      title: Text(l10n.importSaving),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (progress != null && progress.total > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(l10n.importProgress(progress.current, progress.total)),
            ),
          for (var i = 0; i < stages.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    i < stageIndex
                        ? Icons.check_circle_rounded
                        : i == stageIndex
                        ? Icons.lock_rounded
                        : Icons.circle_outlined,
                    size: 20,
                    color: i < stageIndex
                        ? theme.colorScheme.tertiary
                        : i == stageIndex
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(label(stages[i])),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          const LinearProgressIndicator(),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.importDontClose),
          const SizedBox(height: AppSpacing.sm),
          const SecureLabel(),
        ],
      ),
    );
  }
}
