import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/router/routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/ds_colors.dart';
import '../../../core/database/daos/categories_dao.dart';
import '../../../core/database/daos/settings_dao.dart';
import '../../../core/providers.dart';
import '../../../core/security/lock/vault_state.dart';
import '../../../core/widgets/ds_logo.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/secure_label.dart';
import '../../../core/widgets/state_view.dart';
import '../../auth/presentation/reauth/reauth_sheet.dart';

/// Tableau de bord, version du socle (phase 3) : compteur réel, catégories
/// réelles, verrouillage, accès aux réglages de sécurité. Les sections
/// « Scanner », « Importer », échéances et favoris arrivent en phase 4 :
/// aucun bouton factice d'ici là.
final class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final db = ref.watch(databaseProvider);
    final count = ref.watch(_documentCountProvider);
    final categories = ref.watch(_categoriesProvider);
    final recoveryConfirmed = ref.watch(_recoveryConfirmedProvider).value ?? true;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const DsLogo(size: 28),
            const SizedBox(width: AppSpacing.md),
            Text(l10n.appName),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.homeSettings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(Routes.settingsSecurity),
          ),
          IconButton(
            tooltip: l10n.homeLock,
            icon: const Icon(Icons.lock_outline_rounded),
            onPressed: () => ref
                .read(vaultControllerProvider.notifier)
                .lock(currentLocation: Routes.home),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeDocumentCount(count.value ?? 0),
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                const SecureLabel(plural: true),
              ],
            ),
          ),
          if (!recoveryConfirmed)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMargin,
              ),
              child: InfoBanner(
                kind: InfoBannerKind.warning,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.homeRecoveryBanner),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton.tonal(
                      onPressed: () async {
                        if (await requestReauth(context, ref) &&
                            context.mounted) {
                          await context.push(Routes.recoveryKeyFirstTime);
                        }
                      },
                      child: Text(l10n.homeRecoveryAction),
                    ),
                  ],
                ),
              ),
            ),
          if ((count.value ?? 0) == 0)
            SizedBox(
              height: 320,
              child: StateView(
                icon: Icons.folder_open_rounded,
                title: l10n.homeEmptyTitle,
                body: l10n.homeEmptyBody,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenMargin,
              AppSpacing.lg,
              AppSpacing.screenMargin,
              AppSpacing.sm,
            ),
            child: Text(l10n.homeCategories, style: theme.textTheme.titleMedium),
          ),
          switch (categories) {
            AsyncData(:final value) => _CategoryList(value),
            AsyncError() => Padding(
              padding: const EdgeInsets.all(AppSpacing.screenMargin),
              child: Text(l10n.commonErrorBody),
            ),
            _ => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator.adaptive()),
            ),
          },
          // Le provider de la base est observé pour que l'écran se reconstruise
          // si la session change ; la valeur elle-même sert aux DAO ci-dessus.
          if (db.settingsDao != ref.read(databaseProvider).settingsDao)
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

final class _CategoryList extends StatelessWidget {
  const _CategoryList(this.items);

  final List<CategoryWithCount> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.dsColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
      child: Card(
        child: Column(
          children: [
            for (final item in items)
              ListTile(
                leading: _CategoryIcon(
                  icon: _iconFor(item.category.icon),
                  color: ds.categoryOf(item.category.color),
                ),
                title: Text(item.category.name),
                subtitle: Text(l10n.homeCategoryCount(item.documentCount)),
              ),
          ],
        ),
      ),
    );
  }

  /// Icônes intégrées à Flutter, version arrondie (docs/07-design.md §6).
  static IconData _iconFor(String name) => switch (name) {
    'badge' => Icons.badge_rounded,
    'school' => Icons.school_rounded,
    'work' => Icons.work_rounded,
    'account_balance_wallet' => Icons.account_balance_wallet_rounded,
    'home_work' => Icons.home_work_rounded,
    'medical_services' => Icons.medical_services_rounded,
    _ => Icons.folder_rounded,
  };
}

final class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.icon, required this.color});

  final IconData icon;
  final CategoryColor color;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: color.container,
      borderRadius: BorderRadius.circular(AppRadius.categoryIcon),
    ),
    child: Icon(icon, color: color.onContainer, size: 22),
  );
}

final _documentCountProvider = StreamProvider<int>((ref) {
  final state = ref.watch(vaultControllerProvider);
  if (state is! VaultUnlocked) {
    return const Stream.empty();
  }
  return state.session.database.documentsDao.watchCount();
});

/// Vrai une fois la clé de récupération notée par l'utilisateur.
final _recoveryConfirmedProvider = StreamProvider<bool>((ref) {
  final state = ref.watch(vaultControllerProvider);
  if (state is! VaultUnlocked) {
    return const Stream.empty();
  }
  return state.session.database.settingsDao.watchFlag(
    VaultConfigKeys.recoveryKeyConfirmed,
  );
});

final _categoriesProvider = StreamProvider<List<CategoryWithCount>>((ref) {
  final state = ref.watch(vaultControllerProvider);
  if (state is! VaultUnlocked) {
    return const Stream.empty();
  }
  return state.session.database.categoriesDao.watchWithCounts();
});
