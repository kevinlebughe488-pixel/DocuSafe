import 'package:material_ui/material_ui.dart';

import '../../../../app/l10n/generated/app_localizations.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/date_only.dart';
import '../../../../core/utils/formats.dart';
import '../../../../core/widgets/category_icon.dart';

/// Valeurs du formulaire d'un document (importation et modification).
final class DocumentFormValue {
  const DocumentFormValue({
    this.title = '',
    this.categoryId,
    this.docType = '',
    this.description = '',
    this.issueDate,
    this.expirationDate,
    this.tags = const [],
  });

  final String title;
  final String? categoryId;
  final String docType;
  final String description;
  final DateOnly? issueDate;
  final DateOnly? expirationDate;
  final List<String> tags;

  DocumentFormValue copyWith({
    String? title,
    String? categoryId,
    String? docType,
    String? description,
    DateOnly? issueDate,
    bool clearIssue = false,
    DateOnly? expirationDate,
    bool clearExpiration = false,
    List<String>? tags,
  }) => DocumentFormValue(
    title: title ?? this.title,
    categoryId: categoryId ?? this.categoryId,
    docType: docType ?? this.docType,
    description: description ?? this.description,
    issueDate: clearIssue ? null : (issueDate ?? this.issueDate),
    expirationDate: clearExpiration ? null : (expirationDate ?? this.expirationDate),
    tags: tags ?? this.tags,
  );

  bool get isValid => title.trim().isNotEmpty && categoryId != null;
}

/// Formulaire des informations d'un document (écrans 7c et 9b) : nom,
/// catégorie, type, dates, tags, description. Seuls le nom et la catégorie
/// sont obligatoires.
final class DocumentForm extends StatefulWidget {
  const DocumentForm({
    super.key,
    required this.value,
    required this.onChanged,
    required this.categories,
    this.tagSuggestions = const [],
    this.showTitleError = false,
    this.header,
  });

  final DocumentFormValue value;
  final ValueChanged<DocumentFormValue> onChanged;
  final List<CategoryRow> categories;
  final List<String> tagSuggestions;
  final bool showTitleError;

  /// Contenu affiché au-dessus du formulaire (aperçu du fichier).
  final Widget? header;

  @override
  State<DocumentForm> createState() => _DocumentFormState();
}

final class _DocumentFormState extends State<DocumentForm> {
  late final TextEditingController _title = TextEditingController(text: widget.value.title);
  late final TextEditingController _docType = TextEditingController(text: widget.value.docType);
  late final TextEditingController _description = TextEditingController(
    text: widget.value.description,
  );
  final TextEditingController _tag = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _docType.dispose();
    _description.dispose();
    _tag.dispose();
    super.dispose();
  }

  void _update(DocumentFormValue v) => widget.onChanged(v);

  Future<void> _pickDate({required bool expiration}) async {
    final current = expiration ? widget.value.expirationDate : widget.value.issueDate;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current?.toLocalDateTime() ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 50),
      locale: const Locale('fr'),
    );
    if (picked == null) {
      return;
    }
    final d = DateOnly.fromDateTime(picked);
    _update(
      expiration
          ? widget.value.copyWith(expirationDate: d)
          : widget.value.copyWith(issueDate: d),
    );
  }

  void _addTag(String raw) {
    final name = raw.trim();
    if (name.isEmpty || name.length > 30) {
      return;
    }
    final exists = widget.value.tags.any((t) => t.toLowerCase() == name.toLowerCase());
    if (!exists) {
      _update(widget.value.copyWith(tags: [...widget.value.tags, name]));
    }
    _tag.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final v = widget.value;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.md,
        AppSpacing.screenMargin,
        AppSpacing.xxl,
      ),
      children: [
        if (widget.header != null) ...[
          widget.header!,
          const SizedBox(height: AppSpacing.xl),
        ],
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          maxLength: DocumentLimits.maxTitleLength,
          decoration: InputDecoration(
            labelText: l10n.editName,
            counterText: '',
            errorText: widget.showTitleError && v.title.trim().isEmpty
                ? l10n.editNameRequired
                : null,
          ),
          onChanged: (t) => _update(v.copyWith(title: t)),
        ),
        const SizedBox(height: AppSpacing.xl),
        DropdownButtonFormField<String>(
          initialValue: v.categoryId,
          decoration: InputDecoration(labelText: l10n.editCategory),
          items: [
            for (final c in widget.categories)
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
          onChanged: (id) => _update(v.copyWith(categoryId: id)),
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _docType,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.editDocType,
            hintText: l10n.editDocTypeHint,
          ),
          onChanged: (t) => _update(v.copyWith(docType: t)),
        ),
        const SizedBox(height: AppSpacing.xl),
        _DateField(
          label: l10n.editIssueDate,
          value: v.issueDate,
          onTap: () => _pickDate(expiration: false),
          onClear: () => _update(v.copyWith(clearIssue: true)),
        ),
        const SizedBox(height: AppSpacing.xl),
        _DateField(
          label: l10n.editExpirationDate,
          value: v.expirationDate,
          onTap: () => _pickDate(expiration: true),
          onClear: () => _update(v.copyWith(clearExpiration: true)),
        ),
        const SizedBox(height: AppSpacing.xl),
        InputDecorator(
          decoration: InputDecoration(labelText: l10n.editTags),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final t in v.tags)
                InputChip(
                  label: Text(t),
                  onDeleted: () => _update(
                    v.copyWith(tags: v.tags.where((x) => x != t).toList()),
                  ),
                ),
              SizedBox(
                width: 160,
                child: RawAutocomplete<String>(
                  textEditingController: _tag,
                  focusNode: FocusNode(),
                  optionsBuilder: (text) {
                    final q = text.text.trim().toLowerCase();
                    if (q.isEmpty) {
                      return const Iterable.empty();
                    }
                    return widget.tagSuggestions.where(
                      (s) => s.toLowerCase().contains(q) && !v.tags.contains(s),
                    );
                  },
                  onSelected: _addTag,
                  fieldViewBuilder: (context, controller, focus, onSubmit) => TextField(
                    controller: controller,
                    focusNode: focus,
                    decoration: InputDecoration(
                      hintText: l10n.editTagsHint,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (t) {
                      _addTag(t);
                      focus.requestFocus();
                    },
                  ),
                  optionsViewBuilder: (context, onSelected, options) => Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200, maxWidth: 240),
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (final o in options)
                              ListTile(dense: true, title: Text(o), onTap: () => onSelected(o)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _description,
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.editDescription,
            hintText: l10n.editOptional,
            alignLabelWithHint: true,
          ),
          onChanged: (t) => _update(v.copyWith(description: t)),
        ),
      ],
    );
  }
}

final class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final DateOnly? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.field),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          hintText: l10n.editOptional,
          suffixIcon: value == null
              ? const Icon(Icons.calendar_month_outlined)
              : IconButton(
                  tooltip: l10n.editClearDate,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClear,
                ),
        ),
        isEmpty: value == null,
        child: Text(value == null ? '' : Formats.date(value!)),
      ),
    );
  }
}
