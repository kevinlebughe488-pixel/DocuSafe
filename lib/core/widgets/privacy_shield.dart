import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'ds_logo.dart';

/// Écran de masquage quand l'application devient inactive (sélecteur
/// d'applications). Sur Android, `FLAG_SECURE` s'en charge déjà ; ce widget
/// n'agit que sur iOS. **À vérifier sur iOS.**
final class PrivacyShield extends StatefulWidget {
  const PrivacyShield({super.key, required this.child});

  final Widget child;

  @override
  State<PrivacyShield> createState() => _PrivacyShieldState();
}

final class _PrivacyShieldState extends State<PrivacyShield> {
  late final AppLifecycleListener _listener;
  bool _covered = false;

  bool get _enabled => !kIsWeb && Platform.isIOS;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onInactive: () => _set(true),
      onHide: () => _set(true),
      onResume: () => _set(false),
    );
  }

  void _set(bool covered) {
    if (_enabled && covered != _covered) {
      setState(() => _covered = covered);
    }
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      widget.child,
      if (_covered)
        ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: const Center(child: DsLogo(size: 96)),
        ),
    ],
  );
}
