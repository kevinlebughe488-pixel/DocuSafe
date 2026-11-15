import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/router/routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/bottom_actions.dart';
import '../../../core/widgets/illustration_circle.dart';
import '../../documents/presentation/import/import_view_model.dart';
import '../../settings/presentation/permissions/open_phone_settings.dart';
import 'scan_view_model.dart';

/// Onglet Scanner (écran 8) : « Numériser » ouvre le scanner du système ;
/// « Importer des photos » mène à l'importation depuis la galerie.
final class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(scanViewModelProvider);

    Future<void> scan() async {
      await ref.read(scanViewModelProvider.notifier).discard();
      final ok = await ref.read(scanViewModelProvider.notifier).scan();
      if (ok && context.mounted) {
        await context.push(Routes.scanPreview);
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        children: [
          const SizedBox(height: AppSpacing.sm),
          const Center(
            child: IllustrationCircle(icon: Icons.document_scanner_rounded, size: 120),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.scanHeadline,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.scanBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                ErrorMessages.of(l10n, state.error!),
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          // iPhone : appareil photo refusé, accès direct aux réglages.
          if (state.error case ScannerException(cameraDenied: true))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: TextButton.icon(
                onPressed: () => openPhoneSettings(ref),
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(l10n.permissionsOpenSettings),
              ),
            ),
          LargeFilledButton(
            label: l10n.scanStart,
            icon: Icons.photo_camera_rounded,
            onPressed: state.scanning ? null : scan,
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSpacing.largeButtonHeight),
            ),
            onPressed: () {
              ref.read(importViewModelProvider.notifier).reset();
              unawaited(context.push(Routes.documentsImport, extra: ImportSource.gallery));
            },
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(l10n.scanImportPhotos),
          ),
          const SizedBox(height: AppSpacing.xl),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.scanTipsTitle, style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  for (final (icon, text) in [
                    (Icons.wb_sunny_outlined, l10n.scanTipLight),
                    (Icons.straighten_rounded, l10n.scanTipFlat),
                    (Icons.contrast_rounded, l10n.scanTipContrast),
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Row(
                        children: [
                          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              text,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
