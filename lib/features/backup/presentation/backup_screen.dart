import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/router/routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/backup/backup_service.dart';
import '../../../core/database/daos/settings_dao.dart';
import '../../../core/documents/export_document.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers.dart';
import '../../../core/utils/app_log.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formats.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/settings_tile.dart';
import '../../auth/presentation/reauth/reauth_sheet.dart';

/// Dernière sauvegarde enregistrée : (date, taille), ou `null`.
final lastBackupProvider = StreamProvider<(DateTime, int)?>((ref) {
  final dao = ref.watch(databaseProvider).settingsDao;
  return dao.watch().asyncMap((_) async {
    final at = await dao.readConfig(VaultConfigKeys.lastBackupAt);
    final size = await dao.readConfig(VaultConfigKeys.lastBackupSize);
    if (at is! String || size is! int) {
      return null;
    }
    final date = DateTime.tryParse(at);
    return date == null ? null : (date.toLocal(), size);
  });
});

/// Sauvegarde et synchronisation (écran 19b, choix D13).
final class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

final class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final last = ref.watch(lastBackupProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InfoBanner.text(
                  kind: InfoBannerKind.security,
                  text: l10n.backupOnlyHere,
                ),
                const SizedBox(height: AppSpacing.lg),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.settings_backup_restore_rounded,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.backupCardTitle,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  Text(
                                    last == null
                                        ? l10n.backupNever
                                        : l10n.backupLast(
                                            Formats.dateTime(last.$1),
                                            Formats.fileSize(last.$2),
                                          ),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(AppSpacing.touchTarget),
                          ),
                          onPressed: _busy ? null : _create,
                          icon: _busy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(_busy ? l10n.backupInProgress : l10n.backupCreate),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(AppSpacing.touchTarget),
                          ),
                          onPressed: _busy ? null : _restore,
                          icon: const Icon(Icons.restore_rounded),
                          label: Text(l10n.backupRestore),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.backupExplanation,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenMargin,
              AppSpacing.md,
              AppSpacing.screenMargin,
              AppSpacing.xs,
            ),
            child: Text(l10n.backupSyncGroup, style: theme.textTheme.titleSmall),
          ),
          SettingsTile(
            icon: Icons.cloud_off_outlined,
            title: l10n.backupSyncUnavailable,
            subtitle: l10n.backupSyncLater,
            enabled: false,
          ),
        ],
      ),
    );
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final db = ref.read(databaseProvider);
    final confirmed =
        await db.settingsDao.readConfig(VaultConfigKeys.recoveryKeyConfirmed);
    if (!mounted) {
      return;
    }
    if (confirmed != true) {
      // Sans clé de récupération notée, la sauvegarde serait inutilisable.
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.key_rounded),
          title: Text(l10n.backupNeedsKeyTitle),
          content: Text(l10n.backupNeedsKeyBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.backupNeedsKeyAction),
            ),
          ],
        ),
      );
      if (go == true && mounted) {
        await context.push(Routes.settingsRecoveryKey);
      }
      return;
    }
    if (!await requestReauth(context, ref) || !mounted) {
      return;
    }
    final backups = ref.read(backupServiceProvider);
    final share = ref.read(shareServiceProvider);
    final controller = ref.read(vaultControllerProvider.notifier);
    final session = ref.read(sessionProvider);
    final now = ref.read(clockProvider)();
    setState(() => _busy = true);
    controller.beginExternalOperation();
    try {
      final total = await db.documentsDao.watchTotalSize().first;
      final free = await share.freeBytes();
      if (free != null && total + ExportLimits.freeSpaceMargin > free) {
        throw const StorageException('storage.insufficient');
      }
      final file = await backups.create(session, now: now);
      try {
        final size = await file.length();
        final saved = await share.saveFileFrom(
          file,
          fileName: l10n.backupFileName(_isoDate(now), BackupService.fileExtension),
          mimeType: BackupService.mimeType,
        );
        if (saved) {
          await db.settingsDao.writeConfig(
            VaultConfigKeys.lastBackupAt,
            now.toUtc().toIso8601String(),
          );
          await db.settingsDao.writeConfig(VaultConfigKeys.lastBackupSize, size);
          messenger.showSnackBar(SnackBar(content: Text(l10n.backupDone)));
        }
      } finally {
        await backups.discard(file);
      }
    } on AppException catch (e, s) {
      AppLog.error('backup.create', e, s);
      messenger.showSnackBar(SnackBar(content: Text(ErrorMessages.of(l10n, e))));
    } finally {
      controller.endExternalOperation();
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _restore() async {
    if (!await requestReauth(context, ref) || !mounted) {
      return;
    }
    await context.push(Routes.restore);
  }

  static String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
