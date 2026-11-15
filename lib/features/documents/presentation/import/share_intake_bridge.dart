import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/providers.dart';
import '../../../../core/security/lock/vault_state.dart';
import '../../../../core/utils/app_log.dart';
import 'import_view_model.dart';

/// Relie « Partager vers DocSafe » à l'importation : les fichiers reçus
/// attendent que le coffre soit ouvert, puis l'écran d'importation s'ouvre
/// avec eux (vérification, informations, chiffrement).
final class ShareIntakeBridge extends ConsumerStatefulWidget {
  const ShareIntakeBridge({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ShareIntakeBridge> createState() => _ShareIntakeBridgeState();
}

final class _ShareIntakeBridgeState extends ConsumerState<ShareIntakeBridge> {
  @override
  void initState() {
    super.initState();
    unawaited(
      ref
          .read(shareIntakeServiceProvider)
          .initialize(onAvailable: () => unawaited(_fetch())),
    );
  }

  Future<void> _fetch() async {
    final files = await ref.read(shareIntakeServiceProvider).takePending();
    if (files.isEmpty || !mounted) {
      return;
    }
    AppLog.event('share_in.received');
    ref.read(pendingSharesProvider.notifier).add(files);
    _openWhenReady();
  }

  /// Ouvre l'importation dès que le coffre est déverrouillé (après la
  /// redirection du routeur vers l'accueil).
  void _openWhenReady() {
    if (ref.read(vaultControllerProvider) is! VaultUnlocked ||
        ref.read(pendingSharesProvider).isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ref.read(pendingSharesProvider).isEmpty) {
        return;
      }
      final router = ref.read(routerProvider);
      final location = router.routerDelegate.currentConfiguration.uri.path;
      final importer = ref.read(importViewModelProvider.notifier);
      if (location.startsWith(Routes.documentsImport)) {
        unawaited(importer.pick(ImportSource.shared));
      } else {
        importer.reset();
        unawaited(router.push(Routes.documentsImport, extra: ImportSource.shared));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(vaultControllerProvider, (previous, next) {
      if (next is VaultUnlocked && previous is! VaultUnlocked) {
        _openWhenReady();
      }
      if (next is VaultAbsent) {
        // Coffre effacé : les fichiers en attente ne seront pas importés.
        for (final f in ref.read(pendingSharesProvider.notifier).take()) {
          unawaited(f.file.delete().then((_) {}, onError: (_) {}));
        }
      }
    });
    return widget.child;
  }
}
