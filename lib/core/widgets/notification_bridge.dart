import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router/app_router.dart';
import '../../app/router/routes.dart';
import '../providers.dart';
import '../security/lock/vault_state.dart';
import '../utils/app_log.dart';

/// Relie les notifications à l'application :
/// - prépare le service au démarrage ;
/// - une notification touchée ouvre la fiche du document, après le
///   déverrouillage si besoin (docs/07-design.md §8) ;
/// - les rappels sont replanifiés à chaque déverrouillage (§14).
final class NotificationBridge extends ConsumerStatefulWidget {
  const NotificationBridge({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationBridge> createState() => _NotificationBridgeState();
}

final class _NotificationBridgeState extends ConsumerState<NotificationBridge> {
  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    final service = ref.read(notificationServiceProvider);
    try {
      await service.initialize(onTap: _open);
      final launch = await service.launchPayload();
      if (launch != null) {
        _open(launch);
      }
    } on Object catch (e, s) {
      AppLog.error('notifications.init', e, s);
    }
  }

  void _open(String documentId) {
    final location = Routes.document(documentId);
    final controller = ref.read(vaultControllerProvider.notifier);
    if (ref.read(vaultControllerProvider) is VaultUnlocked) {
      unawaited(ref.read(routerProvider).push(location));
    } else {
      controller.openAfterUnlock(location);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(vaultControllerProvider, (previous, next) {
      if (next is VaultUnlocked && previous is! VaultUnlocked) {
        unawaited(ref.read(reminderServiceProvider).rescheduleAll());
      }
    });
    return widget.child;
  }
}
