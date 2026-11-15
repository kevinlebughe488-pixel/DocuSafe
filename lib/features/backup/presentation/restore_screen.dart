import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/router/routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/backup/backup_service.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers.dart';
import '../../../core/reminders/reminder_service.dart';
import '../../../core/security/keys/recovery_key.dart';
import '../../../core/security/lock/vault_state.dart';
import '../../../core/utils/app_log.dart';
import '../../../core/utils/bytes.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formats.dart';
import '../../../core/widgets/bottom_actions.dart';
import '../../../core/widgets/info_banner.dart';
import '../../auth/presentation/widgets/pin_choice.dart';

enum _Step { intro, unpacking, key, pin, restoring }

/// Restaurer une sauvegarde (choix D13) : choisir le fichier, le contrôler,
/// saisir la clé de récupération, choisir un code pour ce téléphone.
///
/// Accessible depuis l'accueil (aucun coffre) ou depuis les réglages (le
/// coffre actuel est alors remplacé, après nouvelle authentification).
final class RestoreScreen extends ConsumerStatefulWidget {
  const RestoreScreen({super.key});

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

final class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  final TextEditingController _keyField = TextEditingController();
  _Step _step = _Step.intro;
  BackupInfo? _info;
  Uint8List? _vaultKey;
  String? _error;
  bool _done = false;

  // Gardé dès le départ : `ref` n'est plus utilisable dans `dispose`.
  late final BackupService _backups = ref.read(backupServiceProvider);

  @override
  void initState() {
    super.initState();
    _backups; // force la lecture tant que l'écran est monté
  }

  @override
  void dispose() {
    _keyField.dispose();
    Bytes.wipe(_vaultKey);
    if (!_done) {
      unawaited(_backups.discardUnpacked());
    }
    super.dispose();
  }

  Future<void> _pick() async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(vaultControllerProvider.notifier);
    setState(() => _error = null);
    controller.beginExternalOperation();
    try {
      final picked = await ref.read(filePickerServiceProvider).pickBackup();
      if (picked == null) {
        return;
      }
      setState(() => _step = _Step.unpacking);
      final info = await _backups.unpack(picked.file);
      await ref.read(filePickerServiceProvider).clearTemporaryFiles();
      setState(() {
        _info = info;
        _step = _Step.key;
      });
    } on AppException catch (e, s) {
      AppLog.error('restore.unpack', e, s);
      setState(() {
        _step = _Step.intro;
        _error = e is ValidationException
            ? l10n.restoreInvalidFile
            : ErrorMessages.of(l10n, e);
      });
    } finally {
      controller.endExternalOperation();
    }
  }

  Future<void> _verifyKey() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _error = null);
    try {
      final key = RecoveryKey.parse(_keyField.text);
      final slot = await _backups.unpackedRecoverySlot();
      final vaultKey = await ref
          .read(vaultControllerProvider.notifier)
          .service
          .unwrapRecoverySlot(slot, key);
      setState(() {
        _vaultKey = vaultKey;
        _step = _Step.pin;
      });
    } on AppException catch (e) {
      setState(() => _error = ErrorMessages.of(l10n, e));
    }
  }

  Future<void> _restore(String pin) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _step = _Step.restoring;
      _error = null;
    });
    try {
      await ref
          .read(vaultControllerProvider.notifier)
          .restoreVault(vaultKey: _vaultKey!, pin: pin);
      _done = true;
      final session = ref.read(vaultControllerProvider.notifier).session;
      if (session != null) {
        unawaited(
          ReminderService(
            database: session.database,
            notifications: ref.read(notificationServiceProvider),
            clock: ref.read(clockProvider),
          ).rescheduleAll(),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.restoreDone)),
        );
        context.go(Routes.home);
      }
    } on Object catch (e, s) {
      AppLog.error('restore.apply', e, s);
      if (mounted) {
        setState(() {
          _step = _Step.pin;
          _error = ErrorMessages.of(l10n, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = _step == _Step.unpacking || _step == _Step.restoring;
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.restoreTitle),
          automaticallyImplyLeading: !busy,
        ),
        body: SafeArea(
          child: switch (_step) {
            _Step.intro => _intro(context, l10n),
            _Step.unpacking => _progress(context, l10n.restoreUnpacking),
            _Step.key => _keyStep(context, l10n),
            _Step.pin => PinChoice(
              title: l10n.restorePinTitle,
              body: l10n.restorePinBody,
              externalError: _error,
              onChosen: _restore,
            ),
            _Step.restoring => _progress(context, l10n.restoreRestoring),
          },
        ),
      ),
    );
  }

  Widget _progress(BuildContext context, String label) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: AppSpacing.lg),
        Text(label, textAlign: TextAlign.center),
      ],
    ),
  );

  Widget _intro(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final replacing = ref.watch(vaultControllerProvider) is VaultUnlocked;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            children: [
              Text(
                l10n.restoreIntro,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (replacing)
                InfoBanner.text(
                  kind: InfoBannerKind.warning,
                  text: l10n.restoreReplaceWarning,
                ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.lg),
                InfoBanner.text(kind: InfoBannerKind.error, text: _error!),
              ],
            ],
          ),
        ),
        BottomActions(
          children: [
            LargeFilledButton(
              label: l10n.restoreChooseFile,
              icon: Icons.folder_open_rounded,
              onPressed: _pick,
            ),
          ],
        ),
      ],
    );
  }

  Widget _keyStep(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final info = _info!;
    final count = RecoveryKey.countValidChars(_keyField.text);
    final complete = count == RecoveryKey.charLength;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            children: [
              InfoBanner.text(
                kind: InfoBannerKind.info,
                text: l10n.restoreFound(
                  Formats.dateTime(info.createdAt),
                  l10n.storageDocumentCount(info.documentCount),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.restoreKeyBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _keyField,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.visiblePassword,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: InputDecoration(
                  labelText: l10n.recoveryFieldLabel,
                  helperText: l10n.recoveryCount(count, RecoveryKey.charLength),
                  errorText: _error,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: complete ? (_) => _verifyKey() : null,
              ),
            ],
          ),
        ),
        BottomActions(
          children: [
            LargeFilledButton(
              label: l10n.recoveryVerify,
              onPressed: complete ? _verifyKey : null,
            ),
          ],
        ),
      ],
    );
  }
}
