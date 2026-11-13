import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/widgets/inactivity_listener.dart';
import '../core/widgets/privacy_shield.dart';
import 'l10n/generated/app_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Racine de l'application : thème, textes, routeur, verrouillage par
/// inactivité et écran de masquage.
final class DocuSafeApp extends ConsumerWidget {
  const DocuSafeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      // La bannière « DEBUG » n'apporte rien sur un coffre-fort.
      debugShowCheckedModeBanner: false,
      builder: (context, child) => PrivacyShield(
        child: InactivityListener(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
