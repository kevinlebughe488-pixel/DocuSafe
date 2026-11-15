import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'core/providers.dart';
import 'core/storage/vault_paths.dart';
import 'core/utils/app_log.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Erreurs imprévues : journalisées sans donnée sensible (type seulement).
  FlutterError.onError = (details) {
    AppLog.error('flutter.error', details.exception, details.stack);
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLog.error('platform.error', error, stack);
    return true;
  };

  final paths = await VaultPaths.resolve();
  AppLog.event('app.started');

  runApp(
    ProviderScope(
      overrides: [vaultPathsProvider.overrideWithValue(paths)],
      child: const DocSafeApp(),
    ),
  );
}
