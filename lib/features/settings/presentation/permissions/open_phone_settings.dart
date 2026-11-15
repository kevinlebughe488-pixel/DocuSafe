import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/providers.dart';

/// Ouvre la page de DocSafe dans les réglages du téléphone ([notifications] :
/// directement ses notifications sur Android).
///
/// Ce passage par les réglages ne verrouille pas le coffre : il compte comme
/// une opération externe (docs/04-securite.md §10), jusqu'au retour dans
/// DocSafe. Au-delà de cinq minutes d'absence, le coffre se verrouille quand
/// même.
Future<void> openPhoneSettings(WidgetRef ref, {bool notifications = false}) async {
  final controller = ref.read(vaultControllerProvider.notifier);
  final service = ref.read(systemSettingsServiceProvider);
  controller.beginExternalOperation();
  var done = false;
  late final AppLifecycleListener listener;
  void finish() {
    if (done) {
      return;
    }
    done = true;
    listener.dispose();
    controller.endExternalOperation();
  }

  listener = AppLifecycleListener(onResume: finish);
  if (!await service.openAppSettings(notifications: notifications)) {
    finish();
  }
}
