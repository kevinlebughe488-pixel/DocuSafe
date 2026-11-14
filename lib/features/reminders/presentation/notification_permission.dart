import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/bottom_actions.dart';
import '../../../core/widgets/illustration_circle.dart';

/// Demande d'autorisation des notifications (maquette 16b) : affichée à la
/// première date d'expiration, jamais au lancement (docs/04-securite.md §14).
/// Explication d'abord, puis demande du système.
Future<void> maybeAskNotificationPermission(BuildContext context, WidgetRef ref) async {
  final service = ref.read(reminderServiceProvider);
  if (!await service.shouldAskPermission() || !context.mounted) {
    return;
  }
  final l10n = AppLocalizations.of(context);
  final allow = await showModalBottomSheet<bool>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IllustrationCircle(icon: Icons.notifications_active_outlined, size: 72),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.permissionTitle,
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.permissionBody, textAlign: TextAlign.center),
            BottomActions(
              children: [
                LargeFilledButton(
                  label: l10n.permissionAllow,
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(l10n.commonLater),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  if (allow ?? false) {
    // La fenêtre du système fait passer l'application en arrière-plan.
    final controller = ref.read(vaultControllerProvider.notifier);
    controller.beginExternalOperation();
    try {
      await service.requestPermission();
    } finally {
      controller.endExternalOperation();
    }
    await service.rescheduleAll();
  }
}
