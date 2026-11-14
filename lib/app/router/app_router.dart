import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/security/lock/vault_state.dart';
import '../../features/auth/presentation/recovery/recovery_screen.dart';
import '../../features/auth/presentation/setup/setup_screen.dart';
import '../../features/auth/presentation/unlock/unlock_screen.dart';
import '../../features/dashboard/presentation/home_screen.dart';
import '../../features/legal/presentation/legal_text_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/settings/presentation/change_pin_screen.dart';
import '../../features/settings/presentation/recovery_key_screen.dart';
import '../../features/settings/presentation/security_settings_screen.dart';
import '../startup/splash_screen.dart';
import 'routes.dart';

/// Signale au routeur chaque changement d'état du coffre.
final class _VaultRefresh extends ChangeNotifier {
  _VaultRefresh(Ref ref) {
    ref.listen(vaultControllerProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _VaultRefresh(ref);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(ref, state.uri.toString()),
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.setup,
        builder: (_, _) => const SetupScreen(),
      ),
      GoRoute(
        path: Routes.lock,
        builder: (_, _) => const UnlockScreen(),
        routes: [
          GoRoute(
            path: 'recovery',
            builder: (_, _) => const RecoveryScreen(),
          ),
        ],
      ),
      GoRoute(
        path: Routes.home,
        builder: (_, _) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.settingsSecurity,
        builder: (_, _) => const SecuritySettingsScreen(),
        routes: [
          GoRoute(
            path: 'pin',
            builder: (_, _) => const ChangePinScreen(),
          ),
          GoRoute(
            path: 'recovery-key',
            builder: (_, state) => RecoveryKeyScreen(
              firstTime: state.uri.queryParameters['first'] == '1',
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.legalPrivacy,
        builder: (_, _) => const LegalTextScreen(text: LegalText.privacy),
      ),
      GoRoute(
        path: Routes.legalTerms,
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
      final allowed = location == Routes.onboarding || location == Routes.setup;
      return allowed ? null : Routes.onboarding;

    case VaultLocked():
      if (location.startsWith(Routes.lock)) {
        return null;
      }
      // Toute autre adresse mène au déverrouillage ; elle est mémorisée dans
      // l'état verrouillé par le contrôleur (voir `lock`).
      return Routes.lock;

    case VaultUnlocked(:final returnLocation):
      final leaving =
          location == Routes.splash ||
          location == Routes.onboarding ||
          location.startsWith(Routes.lock);
      if (leaving) {
        final target = returnLocation;
        final valid =
            target != null &&
            target != Routes.splash &&
            target != Routes.onboarding &&
            !target.startsWith(Routes.lock) &&
            target != Routes.setup;
        return valid ? target : Routes.home;
      }
      // Adresse courante mémorisée pour la rouvrir après un verrouillage.
      if (location != Routes.setup) {
        ref.read(vaultControllerProvider.notifier).rememberLocation(location);
      }
      return null;
  }
}
