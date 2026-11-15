import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/l10n/generated/app_localizations.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/platform/system_settings_service.dart';
import '../../../../core/providers.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/settings_tile.dart';
import 'open_phone_settings.dart';

/// Paramètres → Autorisations : ce que DocSafe peut utiliser sur le
/// téléphone (numérisation, notifications), avec un accès direct aux
/// réglages du téléphone. L'état est relu au retour dans DocSafe.
final class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

final class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  late final AppLifecycleListener _lifecycle;
  CameraAccess? _camera;
  bool? _notifications;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(_refresh()));
    unawaited(_refresh());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final camera = await ref.read(systemSettingsServiceProvider).cameraAccess();
    final notifications = await ref
        .read(notificationServiceProvider)
        .isPermissionGranted();
    if (mounted) {
      setState(() {
        _camera = camera;
        _notifications = notifications;
      });
    }
  }

  /// Une fenêtre du système fait passer DocSafe en arrière-plan : tolérance
  /// le temps de la réponse (docs/04-securite.md §10).
  Future<T> _external<T>(Future<T> Function() action) async {
    final controller = ref.read(vaultControllerProvider.notifier);
    controller.beginExternalOperation();
    try {
      return await action();
    } finally {
      controller.endExternalOperation();
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
      await _refresh();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _onCamera() => _run(() async {
    if (_camera == CameraAccess.notDetermined) {
      final service = ref.read(systemSettingsServiceProvider);
      await _external(service.requestCameraAccess);
    } else {
      await openPhoneSettings(ref);
    }
  });

  /// Désactivées : demande du système, puis ses réglages si la demande ne
  /// peut plus s'afficher (refus répétés). Autorisées : les réglages, pour
  /// pouvoir les couper.
  Future<void> _onNotifications() => _run(() async {
    if (_notifications != true) {
      final reminders = ref.read(reminderServiceProvider);
      if (await _external(reminders.requestPermission)) {
        await reminders.rescheduleAll();
        return;
      }
    }
    await openPhoneSettings(ref, notifications: true);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final camera = _camera;
    final notifications = _notifications;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.permissionsTitle)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            child: InfoBanner.text(kind: InfoBannerKind.security, text: l10n.permissionsIntro),
          ),
          if (camera != null)
            SettingsTile(
              icon: Icons.document_scanner_outlined,
              title: l10n.permissionsScanTitle,
              subtitle: switch (camera) {
                CameraAccess.notNeeded => l10n.permissionsScanNotNeeded,
                CameraAccess.granted => l10n.permissionsCameraGranted,
                CameraAccess.denied => l10n.permissionsCameraDenied,
                CameraAccess.notDetermined => l10n.permissionsCameraAsk,
              },
              // Android : rien à autoriser, ligne d'information seulement.
              onTap: camera == CameraAccess.notNeeded || _busy ? null : _onCamera,
            ),
          if (notifications != null)
            SettingsTile(
              icon: notifications
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              title: l10n.permissionsNotificationsTitle,
              subtitle: notifications
                  ? l10n.permissionsNotificationsGranted
                  : l10n.permissionsNotificationsDenied,
              onTap: _busy ? null : _onNotifications,
            ),
          const Divider(),
          SettingsTile(
            icon: Icons.open_in_new_rounded,
            title: l10n.permissionsOpenSettings,
            trailing: const SizedBox.shrink(),
            onTap: () => openPhoneSettings(ref),
          ),
        ],
      ),
    );
  }
}
