import 'dart:async';

import 'package:flutter/services.dart';

import '../config/app_config.dart';

/// Copie d'une valeur sensible : le presse-papiers est vidé au bout d'une
/// minute (docs/04-securite.md §7). Android 13 et plus masque déjà l'aperçu
/// du presse-papiers pour le texte copié par l'application.
abstract final class SensitiveClipboard {
  static Timer? _timer;

  static Future<void> copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    _timer?.cancel();
    _timer = Timer(AppConfig.clipboardClearDelay, () {
      unawaited(clearIfMatches(value));
    });
  }

  /// Vide le presse-papiers s'il contient encore la valeur copiée.
  static Future<void> clearIfMatches(String value) async {
    final current = await Clipboard.getData(Clipboard.kTextPlain);
    if (current?.text == value) {
      await Clipboard.setData(const ClipboardData(text: ''));
    }
  }
}
