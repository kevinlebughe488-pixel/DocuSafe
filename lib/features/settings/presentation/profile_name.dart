import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../core/database/daos/settings_dao.dart';
import '../../../core/providers.dart';

/// Nom du profil local (facultatif), enregistré dans la base chiffrée et
/// jamais transmis : il sert seulement à saluer l'utilisateur sur l'accueil.
final profileNameProvider = StreamProvider<String?>(
  (ref) => ref
      .watch(databaseProvider)
      .settingsDao
      .watchString(VaultConfigKeys.profileName),
);

const int _maxLength = 30;

/// Fenêtre de saisie du nom. Un champ vide efface le nom.
Future<void> editProfileName(BuildContext context, WidgetRef ref) async {
  final dao = ref.read(databaseProvider).settingsDao;
  final current = await dao.readConfig(VaultConfigKeys.profileName);
  if (!context.mounted) {
    return;
  }
  final saved = await showDialog<String>(
    context: context,
    builder: (_) => _ProfileNameDialog(initial: current is String ? current : ''),
  );
  if (saved == null) {
    return;
  }
  final name = saved.trim().replaceAll(RegExp(r'\s+'), ' ');
  await dao.writeConfig(
    VaultConfigKeys.profileName,
    name.isEmpty ? null : name,
  );
}

final class _ProfileNameDialog extends StatefulWidget {
  const _ProfileNameDialog({required this.initial});

  final String initial;

  @override
  State<_ProfileNameDialog> createState() => _ProfileNameDialogState();
}

final class _ProfileNameDialogState extends State<_ProfileNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.profileTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: _maxLength,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: l10n.profileFieldLabel,
          helperText: l10n.profileHelper,
          helperMaxLines: 2,
        ),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
