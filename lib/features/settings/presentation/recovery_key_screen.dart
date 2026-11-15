import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/database/daos/settings_dao.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers.dart';
import '../../../core/security/keys/recovery_key.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/bottom_actions.dart';
import '../../auth/presentation/widgets/recovery_key_view.dart';

/// Clé de récupération : générée à l'ouverture de l'écran, affichée une
/// seule fois. L'éventuelle clé précédente cesse de fonctionner aussitôt.
///
/// Sert à la première prise de note (rappel de l'accueil, D6 révisée) comme
/// au renouvellement depuis les réglages. Le bouton « Terminé » enregistre
/// que l'utilisateur a conservé sa clé.
final class RecoveryKeyScreen extends ConsumerStatefulWidget {
  const RecoveryKeyScreen({super.key, this.firstTime = false});

  /// Première prise de note : titres de la création plutôt que « Nouvelle clé ».
  final bool firstTime;

  @override
  ConsumerState<RecoveryKeyScreen> createState() => _RecoveryKeyScreenState();
}

final class _RecoveryKeyScreenState extends ConsumerState<RecoveryKeyScreen> {
  late final Future<RecoveryKey> _key;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _key = ref.read(vaultControllerProvider.notifier).regenerateRecoveryKey();
  }

  Future<void> _finish() async {
    try {
      await ref
          .read(databaseProvider)
          .settingsDao
          .writeConfig(VaultConfigKeys.recoveryKeyConfirmed, true);
    } on AppException {
      // Le rappel restera affiché : l'utilisateur pourra recommencer.
    }
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final first = widget.firstTime;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          first ? l10n.setupRecoveryTitle : l10n.settingsRecoveryKeyNewTitle,
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: FutureBuilder<RecoveryKey>(
          future: _key,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final error = snapshot.error!;
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.screenMargin),
                child: Column(
                  children: [
                    Text(
                      error is AppException
                          ? ErrorMessages.of(l10n, error)
                          : l10n.errorUnexpected,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: () => context.pop(),
                      child: Text(l10n.commonClose),
                    ),
                  ],
                ),
              );
            }
            final key = snapshot.data;
            if (key == null) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.screenMargin),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          first
                              ? l10n.setupRecoveryBody
                              : l10n.settingsRecoveryKeyNewBody,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        RecoveryKeyView(recoveryKey: key),
                      ],
                    ),
                  ),
                ),
                CheckboxListTile.adaptive(
                  value: _confirmed,
                  onChanged: (v) => setState(() => _confirmed = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(l10n.setupRecoveryChecked),
                ),
                BottomActions(
                  children: [
                    LargeFilledButton(
                      label: l10n.commonDone,
                      onPressed: _confirmed ? _finish : null,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
