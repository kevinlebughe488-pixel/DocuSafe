import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/router/routes.dart';
import '../../../core/utils/formats.dart';
import '../../../core/widgets/settings_tile.dart';
import '../../documents/presentation/share/document_exit_flow.dart';
import 'about_view_model.dart';
import 'storage/storage_screen.dart';

/// Paramètres (écran 18) : sécurité, notifications, catégories, stockage,
/// export des données, sauvegarde, textes légaux, à propos.
final class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final version = ref.watch(appVersionProvider).value;
    final totalSize = ref.watch(totalSizeProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          SettingsTile(
            icon: Icons.shield_outlined,
            title: l10n.settingsSecurityTitle,
            onTap: () => context.push(Routes.settingsSecurity),
          ),
          SettingsTile(
            icon: Icons.notifications_none_rounded,
            title: l10n.settingsNotifications,
            onTap: () => context.push(Routes.settingsNotifications),
          ),
          SettingsTile(
            icon: Icons.category_outlined,
            title: l10n.settingsCategories,
            onTap: () => context.push(Routes.categories),
          ),
          SettingsTile(
            icon: Icons.storage_rounded,
            title: l10n.storageTitle,
            trailing: totalSize == null
                ? null
                : Text(Formats.fileSize(totalSize)),
            onTap: () => context.push(Routes.settingsStorage),
          ),
          SettingsTile(
            icon: Icons.file_download_outlined,
            title: l10n.exportAllTitle,
            subtitle: l10n.exportAllSubtitle,
            onTap: () => runExportAll(context, ref),
          ),
          SettingsTile(
            icon: Icons.settings_backup_restore_rounded,
            title: l10n.backupSettingsTitle,
            onTap: () => context.push(Routes.settingsBackup),
          ),
          const Divider(),
          SettingsTile(
            icon: Icons.policy_outlined,
            title: l10n.settingsPrivacy,
            onTap: () => context.push(Routes.legalPrivacy),
          ),
          SettingsTile(
            icon: Icons.gavel_rounded,
            title: l10n.settingsTerms,
            onTap: () => context.push(Routes.legalTerms),
          ),
          SettingsTile(
            icon: Icons.info_outline_rounded,
            title: l10n.settingsAbout,
            subtitle: version == null
                ? null
                : l10n.settingsAboutVersion(version),
            onTap: () => context.push(Routes.settingsAbout),
          ),
        ],
      ),
    );
  }
}
