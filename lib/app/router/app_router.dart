import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' show GlobalKey, NavigatorState;

import '../../core/providers.dart';
import '../../core/security/lock/vault_state.dart';
import '../../features/auth/presentation/recovery/recovery_screen.dart';
import '../../features/auth/presentation/setup/setup_screen.dart';
import '../../features/auth/presentation/unlock/unlock_screen.dart';
import '../../features/backup/presentation/backup_screen.dart';
import '../../features/backup/presentation/restore_screen.dart';
import '../../features/categories/presentation/categories_screen.dart';
import '../../features/categories/presentation/category_edit_screen.dart';
import '../../features/dashboard/presentation/home_screen.dart';
import '../../features/documents/presentation/delete/delete_document_screen.dart';
import '../../features/documents/presentation/detail/document_detail_screen.dart';
import '../../features/documents/presentation/edit/document_edit_screen.dart';
import '../../features/documents/presentation/import/import_info_screen.dart';
import '../../features/documents/presentation/import/import_screen.dart';
import '../../features/documents/presentation/import/import_view_model.dart';
import '../../features/documents/presentation/list/documents_screen.dart';
import '../../features/documents/presentation/list/documents_view_model.dart';
import '../../features/documents/presentation/viewer/document_viewer_screen.dart';
import '../../features/legal/presentation/legal_text_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/reminders/presentation/deadlines_screen.dart';
import '../../features/reminders/presentation/document_reminders_screen.dart';
import '../../features/scanner/presentation/scan_preview_screen.dart';
import '../../features/scanner/presentation/scan_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/settings/presentation/about_screen.dart';
import '../../features/settings/presentation/change_pin_screen.dart';
import '../../features/settings/presentation/help/help_screen.dart';
import '../../features/settings/presentation/notification_settings_screen.dart';
import '../../features/settings/presentation/recovery_key_screen.dart';
import '../../features/settings/presentation/security_settings_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/storage/storage_screen.dart';
import '../shell/app_shell.dart';
import '../startup/splash_screen.dart';
import 'routes.dart';

/// Signale au routeur chaque changement d'état du coffre.
final class _VaultRefresh extends ChangeNotifier {
  _VaultRefresh(Ref ref) {
    ref.listen(vaultControllerProvider, (_, _) => notifyListeners());
  }
}

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _VaultRefresh(ref);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(ref, state.uri.toString()),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.onboarding, builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: Routes.setup, builder: (_, _) => const SetupScreen()),
      GoRoute(
        path: Routes.lock,
        builder: (_, _) => const UnlockScreen(),
        routes: [
          GoRoute(path: 'recovery', builder: (_, _) => const RecoveryScreen()),
        ],
      ),

      // Onglets principaux, avec la barre du bas.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.documents,
                builder: (_, state) => DocumentsScreen(
                  key: ValueKey(state.uri.query),
                  initialTab: switch (state.uri.queryParameters['tab']) {
                    'favorites' => DocumentsTab.favorites,
                    'recent' => DocumentsTab.recent,
                    _ => null,
                  },
                  initialCategoryId: state.uri.queryParameters['category'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.scan, builder: (_, _) => const ScanScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.deadlines, builder: (_, _) => const DeadlinesScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen())],
          ),
        ],
      ),

      // Écrans plein écran (sans barre du bas).
      GoRoute(
        path: Routes.scanPreview,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const ScanPreviewScreen(),
      ),
      GoRoute(
        path: Routes.search,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const SearchScreen(),
      ),
      GoRoute(
        path: Routes.documentsImport,
        parentNavigatorKey: _rootKey,
        builder: (_, state) => ImportScreen(
          initialSource: state.extra is ImportSource ? state.extra! as ImportSource : null,
        ),
        routes: [
          GoRoute(path: 'info', builder: (_, _) => const ImportInfoScreen()),
        ],
      ),
      GoRoute(
        path: '/documents/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => DocumentDetailScreen(documentId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'view',
            builder: (_, state) => DocumentViewerScreen(documentId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'edit',
            builder: (_, state) => DocumentEditScreen(documentId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'delete',
            builder: (_, state) => DeleteDocumentScreen(documentId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: Routes.categories,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const CategoriesScreen(),
        routes: [
          GoRoute(path: 'new', builder: (_, _) => const CategoryEditScreen()),
          GoRoute(
            path: ':id',
            builder: (_, state) => CategoryEditScreen(categoryId: state.pathParameters['id']),
          ),
        ],
      ),
      GoRoute(
        path: Routes.settingsSecurity,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const SecuritySettingsScreen(),
        routes: [
          GoRoute(path: 'pin', builder: (_, _) => const ChangePinScreen()),
          GoRoute(
            path: 'recovery-key',
            builder: (_, state) => RecoveryKeyScreen(
              firstTime: state.uri.queryParameters['first'] == '1',
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/deadlines/:id/reminders',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => DocumentRemindersScreen(documentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.settingsNotifications,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: Routes.settingsAbout,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const AboutScreen(),
      ),
      GoRoute(
        path: Routes.settingsStorage,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const StorageScreen(),
      ),
      GoRoute(
        path: Routes.settingsBackup,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const BackupScreen(),
      ),
      GoRoute(
        path: Routes.settingsHelp,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const HelpScreen(),
      ),
      GoRoute(
        path: Routes.restore,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const RestoreScreen(),
      ),
      GoRoute(
        path: Routes.legalPrivacy,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const LegalTextScreen(text: LegalText.privacy),
      ),
      GoRoute(
        path: Routes.legalTerms,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const LegalTextScreen(text: LegalText.terms),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Redirections automatiques (docs/02-architecture.md §5) : appliquées avant
/// d'afficher quoi que ce soit.
String? _redirect(Ref ref, String location) {
  final vault = ref.read(vaultControllerProvider);
  if (Routes.isPublic(location)) {
    return null;
  }
  switch (vault) {
    case VaultInitializing():
      return location == Routes.splash ? null : Routes.splash;

    case VaultAbsent():
      final allowed = location == Routes.onboarding ||
          location == Routes.setup ||
          location == Routes.restore;
      return allowed ? null : Routes.onboarding;

    case VaultLocked():
      if (location.startsWith(Routes.lock)) {
        return null;
      }
      return Routes.lock;

    case VaultUnlocked(:final returnLocation):
      // « Code oublié » : la clé de récupération ouvre le coffre, puis
      // l'écran reste affiché pour choisir un nouveau code.
      final leaving =
          location == Routes.splash ||
          location == Routes.onboarding ||
          (location.startsWith(Routes.lock) && location != Routes.lockRecovery);
      if (leaving) {
        final target = returnLocation;
        final valid =
            target != null &&
            target != Routes.splash &&
            target != Routes.onboarding &&
            !target.startsWith(Routes.lock) &&
            target != Routes.setup &&
            // Une importation ou un scan interrompu par un verrouillage
            // recommence (les fichiers temporaires ont été purgés).
            !target.startsWith(Routes.documentsImport) &&
            target != Routes.scanPreview;
        return valid ? target : Routes.home;
      }
      if (location != Routes.setup) {
        ref.read(vaultControllerProvider.notifier).rememberLocation(location);
      }
      return null;
  }
}
