import 'dart:io';

import 'package:flutter/services.dart';

import '../utils/app_log.dart';
import 'file_picker_service.dart';

/// « Partager vers DocSafe » (cahier des charges §3.4) : fichiers envoyés à
/// DocSafe depuis une autre application.
///
/// Sur Android, `MainActivity` copie les fichiers reçus dans `cache/shared_in`
/// et prévient Dart. Ils suivent ensuite l'importation habituelle
/// (vérification, chiffrement), après déverrouillage du coffre. Sur iPhone,
/// l'extension de partage est reportée après le MVP (autorisé par le cahier
/// des charges) : aucun fichier n'arrive.
abstract interface class ShareIntakeService {
  /// Branche le service ; [onAvailable] est appelé quand des fichiers
  /// attendent d'être repris avec [takePending].
  Future<void> initialize({required void Function() onAvailable});

  /// Fichiers reçus et pas encore repris (liste vide sinon).
  Future<List<PickedFile>> takePending();
}

final class PlatformShareIntakeService implements ShareIntakeService {
  const PlatformShareIntakeService();

  static const _channel = MethodChannel('docusafe/share_in');

  @override
  Future<void> initialize({required void Function() onAvailable}) async {
    if (!Platform.isAndroid) {
      return;
    }
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'sharedAvailable') {
        onAvailable();
      }
    });
    // Fichiers reçus avant que l'interface ne soit prête.
    onAvailable();
  }

  @override
  Future<List<PickedFile>> takePending() async {
    if (!Platform.isAndroid) {
      return const [];
    }
    try {
      final items = await _channel.invokeListMethod<Map<Object?, Object?>>('takePending');
      return [
        for (final item in items ?? const <Map<Object?, Object?>>[])
          if (item['path'] is String && item['name'] is String)
            PickedFile(
              file: File(item['path']! as String),
              displayName: item['name']! as String,
            ),
      ];
    } on PlatformException catch (e, s) {
      AppLog.error('share_in.take', e, s);
      return const [];
    } on MissingPluginException {
      return const [];
    }
  }
}

/// Version simulée pour les tests : [deliver] imite un partage reçu.
final class FakeShareIntakeService implements ShareIntakeService {
  final List<PickedFile> _pending = [];
  void Function()? _onAvailable;

  void deliver(List<PickedFile> files) {
    _pending
      ..clear()
      ..addAll(files);
    _onAvailable?.call();
  }

  @override
  Future<void> initialize({required void Function() onAvailable}) async {
    _onAvailable = onAvailable;
    if (_pending.isNotEmpty) {
      onAvailable();
    }
  }

  @override
  Future<List<PickedFile>> takePending() async {
    final files = List<PickedFile>.of(_pending);
    _pending.clear();
    return files;
  }
}
