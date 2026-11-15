import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/ds_logo.dart';
import '../../../core/widgets/secure_label.dart';
import '../../../core/widgets/settings_tile.dart';
import 'about_view_model.dart';

/// À propos : version et licences des composants (obligation des licences
/// permissives, docs/06-dependances.md).
final class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final version = ref.watch(appVersionProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAbout)),
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.xl),
          const Center(child: DsLogo(size: 72)),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(l10n.appName, style: theme.textTheme.headlineSmall),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: Text(
              l10n.appTagline,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              version.value == null ? '' : l10n.settingsAboutVersion(version.value!),
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Center(child: SecureLabel()),
          const SizedBox(height: AppSpacing.xl),
          SettingsTile(
            icon: Icons.description_outlined,
            title: l10n.settingsLicenses,
            onTap: () => showLicensePage(
              context: context,
              applicationName: l10n.appName,
              applicationVersion: version.value,
            ),
          ),
        ],
      ),
    );
  }
}
