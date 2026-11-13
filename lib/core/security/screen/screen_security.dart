import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../utils/app_log.dart';

/// Protection de l'écran (docs/04-securite.md §15).
///
/// Android : `FLAG_SECURE` posé par `MainActivity` dès le démarrage ; ce
/// service permet de le retirer si l'utilisateur autorise les captures.
/// iOS : les captures ne peuvent pas être bloquées ; l'écran de masquage
/// quand l'application devient inactive est géré côté Dart par
/// `PrivacyShield` (à vérifier sur iOS).
abstract interface class ScreenSecurity {
  Future<void> setSecure(bool secure);
}

final class ChannelScreenSecurity implements ScreenSecurity {
  const ChannelScreenSecurity();

  static const MethodChannel _channel = MethodChannel('docusafe/screen_security');

  @override
  Future<void> setSecure(bool secure) async {
    if (kIsWeb || !Platform.isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('setSecure', {'secure': secure});
    } on MissingPluginException {
      // Tests ou plateforme sans canal : rien à faire.
    } on PlatformException catch (e, s) {
      AppLog.error('screen_security.set', e, s);
    }
  }
}

final class NoopScreenSecurity implements ScreenSecurity {
  const NoopScreenSecurity();

  @override
  Future<void> setSecure(bool secure) async {}
}
