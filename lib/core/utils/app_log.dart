import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Journal technique unique de l'application (docs/04-securite.md §15).
///
/// Il n'accepte que des codes d'événement et des types d'erreur : jamais de
/// titre, de chemin, de contenu de document ni de clé. En production, rien
/// n'est écrit du tout.
abstract final class AppLog {
  /// Enregistre un événement nommé par un code court (ex. `vault.unlocked`).
  static void event(String code) {
    if (!kDebugMode) {
      return;
    }
    developer.log(code, name: 'docusafe');
  }

  /// Enregistre une erreur par son type et son code, sans son message.
  ///
  /// Le message d'une erreur venant d'un paquet tiers pourrait contenir un
  /// chemin de fichier : il n'est volontairement pas journalisé.
  static void error(String code, Object error, [StackTrace? stackTrace]) {
    if (!kDebugMode) {
      return;
    }
    developer.log(
      '$code (${error.runtimeType})',
      name: 'docusafe',
      level: 1000,
      stackTrace: stackTrace,
    );
  }
}
