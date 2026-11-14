import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'dart_crypto_engine.dart';
import 'file_cipher.dart';

/// Chiffrement et déchiffrement de fichiers **hors du fil d'exécution de
/// l'interface** (docs/02-architecture.md §8) : chaque opération s'exécute
/// dans un isolate éphémère avec son propre [FileCipher].
///
/// Les clés passées sont copiées vers l'isolate ; l'appelant reste
/// responsable d'effacer les siennes.
abstract final class CryptoWorker {
  static Future<FileCipherResult> encryptFile({
    required File source,
    required File destination,
    required Uint8List rootKey,
  }) {
    final src = source.path;
    final dst = destination.path;
    final key = Uint8List.fromList(rootKey);
    return Isolate.run(
      () => FileCipher(const DartCryptoEngine()).encryptFile(
        source: File(src),
        destination: File(dst),
        rootKey: key,
      ),
      debugName: 'encryptFile',
    );
  }

  static Future<FileCipherResult> decryptFile({
    required File source,
    required File destination,
    required Uint8List rootKey,
  }) {
    final src = source.path;
    final dst = destination.path;
    final key = Uint8List.fromList(rootKey);
    return Isolate.run(
      () => FileCipher(const DartCryptoEngine()).decryptFile(
        source: File(src),
        destination: File(dst),
        rootKey: key,
      ),
      debugName: 'decryptFile',
    );
  }

  /// Déchiffre un fichier en mémoire. Réservé aux fichiers de taille modérée.
  static Future<(Uint8List, FileCipherResult)> decryptFileToMemory({
    required File source,
    required Uint8List rootKey,
  }) {
    final src = source.path;
    final key = Uint8List.fromList(rootKey);
    return Isolate.run(() async {
      final builder = BytesBuilder(copy: false);
      final result = await FileCipher(const DartCryptoEngine()).decryptStream(
        input: File(src).openRead(),
        output: builder.add,
        rootKey: key,
      );
      return (builder.takeBytes(), result);
    }, debugName: 'decryptToMemory');
  }

  /// Relit un fichier chiffré sans conserver le clair : vérifie l'intégrité
  /// et retourne l'empreinte (relecture de contrôle après écriture).
  static Future<FileCipherResult> verifyFile({
    required File source,
    required Uint8List rootKey,
  }) {
    final src = source.path;
    final key = Uint8List.fromList(rootKey);
    return Isolate.run(
      () => FileCipher(const DartCryptoEngine()).decryptStream(
        input: File(src).openRead(),
        output: (_) {},
        rootKey: key,
      ),
      debugName: 'verifyFile',
    );
  }

  /// Chiffre de petites données (miniature) en mémoire.
  static Future<Uint8List> encryptBytes({
    required Uint8List plaintext,
    required Uint8List rootKey,
  }) {
    final data = Uint8List.fromList(plaintext);
    final key = Uint8List.fromList(rootKey);
    return Isolate.run(
      () => FileCipher(const DartCryptoEngine()).encryptBytes(
        plaintext: data,
        rootKey: key,
      ),
      debugName: 'encryptBytes',
    );
  }
}
