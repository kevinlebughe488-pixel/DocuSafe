import 'dart:io';

import 'package:flutter/services.dart';

import '../utils/app_log.dart';

/// Exclut le coffre des sauvegardes automatiques de l'iPhone (iCloud et
/// ordinateur) : cahier des charges §3.7, docs/04-securite.md §15.
///
/// Sur Android, la même exclusion vient du manifeste (`allowBackup=false`,
/// règles d'extraction vides) : rien à faire ici. À vérifier sur iOS.
abstract final class BackupExclusion {
  static const _channel = MethodChannel('docusafe/platform');

  static Future<void> exclude(Directory dir) async {
    if (!Platform.isIOS) {
      return;
    }
    try {
      await _channel.invokeMethod<bool>('excludeFromBackup', {'path': dir.path});
    } on PlatformException catch (e, s) {
      AppLog.error('backup_exclusion', e, s);
    } on MissingPluginException catch (e, s) {
      AppLog.error('backup_exclusion.missing', e, s);
    }
  }
}
