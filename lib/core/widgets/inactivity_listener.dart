import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// Relance le compte à rebours du verrouillage à chaque interaction.
final class InactivityListener extends ConsumerWidget {
  const InactivityListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) => ref.read(vaultControllerProvider.notifier).touch(),
    onPointerSignal: (_) => ref.read(vaultControllerProvider.notifier).touch(),
    child: child,
  );
}
