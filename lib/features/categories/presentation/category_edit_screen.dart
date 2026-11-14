import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/ds_colors.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/default_categories.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../core/widgets/settings_tile.dart';
import 'categories_screen.dart';

/// Création ou modification d'une catégorie (écran 11b) : nom, icône,
/// couleur, avec aperçu immédiat. Suppression avec déplacement des
/// documents (écran 11c).
final class CategoryEditScreen extends ConsumerStatefulWidget {
  const CategoryEditScreen({super.key, this.categoryId});

  /// `null` : nouvelle catégorie.
  final String? categoryId;

  @override
  ConsumerState<CategoryEditScreen> createState() => _CategoryEditScreenState();
}

final class _CategoryEditScreenState extends ConsumerState<CategoryEditScreen> {
  final _name = TextEditingController();
  String _icon = 'folder';
  String _colorKey = 'blue';
  CategoryRow? _existing;
  int _documentCount = 0;
  bool _loaded = false;
  bool _busy = false;
  String? _error;

  bool get _isNew => widget.categoryId == null;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final id = widget.categoryId;
    if (id != null) {
      final db = ref.read(databaseProvider);
      final row = await db.categoriesDao.getById(id);
      final counts = await db.categoriesDao.watchWithCounts().first;
      if (row != null && mounted) {
        _existing = row;
        _name.text = row.name;
        _icon = row.icon;
        _colorKey = CategoryColors.keyOf(row.color);
        _documentCount = counts
            .firstWhere((c) => c.category.id == id)
            .documentCount;
      }
    }
    if (mounted) {
      setState(() => _loaded = true);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.categoryNameRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final dao = ref.read(databaseProvider).categoriesDao;
    final color = CategoryColors.reference[_colorKey]!;
    try {
      if (_isNew) {
        await dao.create(name: name, icon: _icon, color: color);
      } else {
        await dao.edit(_existing!.id, name: name, icon: _icon, color: color);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.categorySaved)),
        );
        context.pop();
      }
    } on ValidationException catch (e) {
      setState(() {
        _busy = false;
        _error = e.code == 'validation.category_duplicate'
            ? l10n.categoryNameDuplicate
            : ErrorMessages.of(l10n, e);
      });
    } on AppException catch (e) {
      setState(() {
        _busy = false;
        _error = ErrorMessages.of(l10n, e);
      });
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final existing = _existing!;
    final all = (await ref.read(categoriesWithCountsProvider.future))
        .map((c) => c.category)
        .where((c) => c.id != existing.id)
        .toList();
    if (!mounted) {
      return;
    }
    final target = await showDialog<String>(
      context: context,
      builder: (_) => _DeleteCategoryDialog(
        category: existing,
        documentCount: _documentCount,
        targets: all,
      ),
    );
    if (target == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(databaseProvider)
          .categoriesDao
          .deleteMovingDocuments(existing.id, targetCategoryId: target);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.categoryDeleted)),
        );
        context.pop();
      }
    } on AppException catch (e) {
      setState(() {
        _busy = false;
        _error = ErrorMessages.of(l10n, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ds = context.dsColors;
    final color = CategoryColors.reference[_colorKey]!;
    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: Text(_isNew ? l10n.categoryNewTitle : l10n.categoryEditTitle),
        actions: [
          TextButton(
            onPressed: _busy || !_loaded ? null : _save,
            child: Text(l10n.commonSave),
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator.adaptive())
          : ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: [
                const SizedBox(height: AppSpacing.sm),
                Center(child: CategoryIcon(icon: _icon, color: color, size: 64)),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Text(
                    _name.text.trim().isEmpty ? l10n.categoryName : _name.text.trim(),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (!_isNew)
                  Center(
                    child: Text(
                      l10n.homeCategoryCount(_documentCount),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenMargin,
                    AppSpacing.xl,
                    AppSpacing.screenMargin,
                    0,
                  ),
                  child: TextField(
                    controller: _name,
                    autofocus: _isNew,
                    maxLength: 40,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.categoryName,
                      errorText: _error,
                      counterText: '',
                    ),
                    onChanged: (_) => setState(() => _error = null),
                  ),
                ),
                SettingsGroupLabel(l10n.categoryIcon),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenMargin,
                  ),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final entry in CategoryIcons.all.entries)
                        _IconOption(
                          icon: entry.value,
                          selected: entry.key == _icon,
                          color: ds.categoryOf(color),
                          onTap: () => setState(() => _icon = entry.key),
                        ),
                    ],
                  ),
                ),
                SettingsGroupLabel(l10n.categoryColor),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenMargin,
                  ),
                  child: Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      for (final c in ds.categories)
                        Semantics(
                          button: true,
                          selected: c.key == _colorKey,
                          label: l10n.categoryColorName(c.key),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => setState(() => _colorKey = c.key),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: c.container,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: c.key == _colorKey
                                      ? c.onContainer
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: c.key == _colorKey
                                  ? Icon(Icons.check_rounded, color: c.onContainer)
                                  : Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: c.onContainer,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!_isNew && !_existing!.isSystem) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenMargin,
                    ),
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      onPressed: _busy ? null : _delete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(l10n.categoryDelete),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

final class _IconOption extends StatelessWidget {
  const _IconOption({
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final CategoryColor color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? color.container : scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppRadius.categoryIcon),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.categoryIcon),
        onTap: onTap,
        child: SizedBox.square(
          dimension: 48,
          child: Icon(
            icon,
            color: selected ? color.onContainer : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// « Supprimer « Immobilier » ? Ses 9 documents ne seront pas supprimés… »
final class _DeleteCategoryDialog extends StatefulWidget {
  const _DeleteCategoryDialog({
    required this.category,
    required this.documentCount,
    required this.targets,
  });

  final CategoryRow category;
  final int documentCount;
  final List<CategoryRow> targets;

  @override
  State<_DeleteCategoryDialog> createState() => _DeleteCategoryDialogState();
}

final class _DeleteCategoryDialogState extends State<_DeleteCategoryDialog> {
  late String _target = widget.targets
      .firstWhere(
        (c) => c.id == DefaultCategory.othersId,
        orElse: () => widget.targets.first,
      )
      .id;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasDocs = widget.documentCount > 0;
    return AlertDialog.adaptive(
      title: Text(l10n.categoryDeleteTitle(widget.category.name)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.categoryDeleteBody(widget.documentCount)),
          if (hasDocs) ...[
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              initialValue: _target,
              decoration: InputDecoration(labelText: l10n.categoryMoveTo),
              items: [
                for (final c in widget.targets)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) => setState(() => _target = v ?? _target),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(_target),
          child: Text(
            hasDocs ? l10n.categoryDeleteAction : l10n.categoryDeleteOnlyAction,
          ),
        ),
      ],
    );
  }
}
