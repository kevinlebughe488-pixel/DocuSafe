import 'package:material_ui/material_ui.dart';

import '../../core/widgets/ds_logo.dart';
import '../../core/widgets/secure_label.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_spacing.dart';

/// Écran de démarrage : visible le temps de lire le stockage sécurisé.
/// Le routeur redirige dès que l'état du coffre est connu.
final class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const DsLogo(size: 96),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      l10n.appName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.appTagline,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.lg),
              child: SecureLabel(),
            ),
          ],
        ),
      ),
    );
  }
}
