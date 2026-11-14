import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/l10n/generated/app_localizations.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../reminders/presentation/notification_permission.dart';
import 'document_form.dart';

/// Modification des informations d'un document (écran 7c).
final class DocumentEditScreen extends ConsumerStatefulWidget {
  const DocumentEditScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<DocumentEditScreen> createState() => _DocumentEditScreenState();
}

final class _DocumentEditScreenState extends ConsumerState<DocumentEditScreen> {
  DocumentFormValue? _value;
  List<CategoryRow> _categories = const [];
  List<String> _suggestions = const [];
  bool _busy = false;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final repo = ref.read(documentRepositoryProvider);
    final doc = await db.documentsDao.getById(widget.documentId);
    final categories = await db.categoriesDao.getAll();
    final tags = await repo.tagsOf(widget.documentId);
    final suggestions = await repo.allTagNames();
    if (!mounted || doc == null) {
      return;
    }
    setState(() {
      _categories = categories;
      _suggestions = suggestions;
      _value = DocumentFormValue(
        title: doc.title,
        categoryId: doc.categoryId,
        docType: doc.docType ?? '',
        description: doc.description ?? '',
        issueDate: doc.issueDate,
        expirationDate: doc.expirationDate,
        tags: tags.map((t) => t.name).toList(),
      );
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final v = _value;
    if (v == null) {
      return;
    }
    if (!v.isValid) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(documentRepositoryProvider).updateInfo(
        widget.documentId,
        title: v.title,
        categoryId: v.categoryId!,
        docType: v.docType,
        description: v.description,
        issueDate: v.issueDate,
        expirationDate: v.expirationDate,
        tags: v.tags,
      );
      await ref.read(reminderServiceProvider).syncDocument(widget.documentId);
      if (mounted && v.expirationDate != null) {
        await maybeAskNotificationPermission(context, ref);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.editSaved)),
        );
        context.pop();
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
    final v = _value;
    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: Text(l10n.editTitle),
        actions: [
          TextButton(
            onPressed: v == null || _busy ? null : _save,
            child: Text(l10n.commonSave),
          ),
        ],
      ),
      body: v == null
          ? const Center(child: CircularProgressIndicator.adaptive())
          : DocumentForm(
              value: v,
              categories: _categories,
              tagSuggestions: _suggestions,
              showTitleError: _showErrors,
              onChanged: (nv) => setState(() => _value = nv),
            ),
    );
  }
}
