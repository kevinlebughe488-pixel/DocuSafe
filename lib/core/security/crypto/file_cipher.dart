import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import '../../errors/app_exception.dart';
import '../../utils/bytes.dart';
import 'crypto_engine.dart';
import 'dsf_header.dart';
import 'key_derivation.dart';

/// Résultat d'un chiffrement ou d'un déchiffrement complet.
final class FileCipherResult {
  const FileCipherResult({required this.sha256, required this.plainLength});

  /// Empreinte SHA-256 du contenu en clair.
  final Uint8List sha256;

  /// Taille du contenu en clair, en octets.
  final int plainLength;

  String get sha256Hex => Bytes.toHex(sha256);
}

/// Chiffrement des fichiers par blocs au format `DSF1`
/// (docs/04-securite.md §8).
///
/// Règles mises en œuvre :
/// - une clé par fichier, dérivée de la racine et du sel de l'en-tête ;
/// - chaque bloc est scellé avec sa position et l'en-tête (données
///   authentifiées additionnelles) : déplacer ou échanger des blocs est détecté ;
/// - le dernier bloc est marqué comme dernier : un fichier tronqué est détecté ;
/// - l'empreinte SHA-256 du clair est calculée au fil du traitement ;
/// - la mémoire utilisée reste de l'ordre d'un bloc, quelle que soit la
///   taille du fichier.
final class FileCipher {
  FileCipher(this._crypto) : _keys = KeyDerivation(_crypto);

  final CryptoEngine _crypto;
  final KeyDerivation _keys;

  // ---------------------------------------------------------------------------
  // Chiffrement
  // ---------------------------------------------------------------------------

  /// Chiffre le flux [input] et écrit le résultat dans [output].
  ///
  /// [rootKey] est la racine des clés de fichiers (ou de miniatures) issue de
  /// la clé du coffre. Le flux de sortie n'est ni vidé ni fermé ici.
  Future<FileCipherResult> encryptStream({
    required Stream<List<int>> input,
    required void Function(List<int> chunk) output,
    required Uint8List rootKey,
    int? blockSize,
  }) async {
    final header = blockSize == null
        ? DsfHeader.create(_crypto.randomBytes(DsfHeader.saltLength))
        : DsfHeader(
            blockSize: blockSize,
            salt: _crypto.randomBytes(DsfHeader.saltLength),
          );
    final headerBytes = header.encode();
    final fileKey = await _keys.fileKey(rootKey, header.salt);
    try {
      output(headerBytes);
      final hash = _Sha256Accumulator();
      var blockIndex = 0;
      var plainLength = 0;

      // Un bloc est gardé en attente : il n'est chiffré que lorsqu'on sait
      // s'il est le dernier.
      await for (final block in _reblock(input, header.blockSize)) {
        hash.add(block.bytes);
        plainLength += block.bytes.length;
        final sealed = await _crypto.aesGcmEncrypt(
          key: fileKey,
          nonce: _nonce(blockIndex, block.isLast),
          plaintext: block.bytes,
          aad: _aad(headerBytes, blockIndex, block.isLast),
        );
        output(sealed);
        blockIndex++;
      }
      return FileCipherResult(sha256: hash.close(), plainLength: plainLength);
    } finally {
      Bytes.wipe(fileKey);
    }
  }

  /// Chiffre un tableau d'octets en mémoire (miniatures, petits fichiers).
  Future<Uint8List> encryptBytes({
    required Uint8List plaintext,
    required Uint8List rootKey,
    int? blockSize,
  }) async {
    final builder = BytesBuilder(copy: false);
    await encryptStream(
      input: Stream.value(plaintext),
      output: builder.add,
      rootKey: rootKey,
      blockSize: blockSize,
    );
    return builder.takeBytes();
  }

  /// Chiffre [source] vers [destination]. La destination est écrasée.
  ///
  /// Le fichier est vidé sur le stockage (`flush`) avant de retourner.
  Future<FileCipherResult> encryptFile({
    required File source,
    required File destination,
    required Uint8List rootKey,
  }) async {
    final sink = destination.openWrite();
    try {
      final result = await encryptStream(
        input: source.openRead(),
        output: sink.add,
        rootKey: rootKey,
      );
      await sink.flush();
      return result;
    } finally {
      await sink.close();
    }
  }

  // ---------------------------------------------------------------------------
  // Déchiffrement
  // ---------------------------------------------------------------------------

  /// Déchiffre le flux [input]. Chaque bloc en clair est transmis à [output].
  ///
  /// Lève [CryptoException.integrity] à la première anomalie : rien n'est
  /// transmis au-delà du dernier bloc valide, et l'appelant doit jeter ce qu'il
  /// a reçu. Lève [CryptoException.badFormat] si l'en-tête est inconnu.
  Future<FileCipherResult> decryptStream({
    required Stream<List<int>> input,
    required void Function(List<int> chunk) output,
    required Uint8List rootKey,
  }) async {
    final reader = _ChunkReader(input);
    final headerBytes = await reader.readExactly(DsfHeader.length);
    if (headerBytes == null) {
      throw CryptoException.badFormat;
    }
    final header = DsfHeader.decode(headerBytes);
    final fileKey = await _keys.fileKey(rootKey, header.salt);
    try {
      final hash = _Sha256Accumulator();
      var blockIndex = 0;
      var plainLength = 0;
      await for (final block in reader.blocks(header.encryptedBlockSize)) {
        final clear = await _crypto.aesGcmDecrypt(
          key: fileKey,
          nonce: _nonce(blockIndex, block.isLast),
          ciphertextWithTag: block.bytes,
          aad: _aad(headerBytes, blockIndex, block.isLast),
        );
        hash.add(clear);
        plainLength += clear.length;
        output(clear);
        blockIndex++;
      }
      if (blockIndex == 0) {
        // Un fichier DSF contient toujours au moins un bloc (même vide).
        throw CryptoException.integrity;
      }
      return FileCipherResult(sha256: hash.close(), plainLength: plainLength);
    } finally {
      Bytes.wipe(fileKey);
    }
  }

  /// Déchiffre un tableau d'octets en mémoire.
  Future<(Uint8List, FileCipherResult)> decryptBytes({
    required Uint8List ciphertext,
    required Uint8List rootKey,
  }) async {
    final builder = BytesBuilder(copy: false);
    final result = await decryptStream(
      input: Stream.value(ciphertext),
      output: builder.add,
      rootKey: rootKey,
    );
    return (builder.takeBytes(), result);
  }

  /// Déchiffre [source] vers [destination].
  ///
  /// En cas d'erreur d'intégrité, la destination est supprimée.
  Future<FileCipherResult> decryptFile({
    required File source,
    required File destination,
    required Uint8List rootKey,
  }) async {
    final sink = destination.openWrite();
    var failed = false;
    try {
      final result = await decryptStream(
        input: source.openRead(),
        output: sink.add,
        rootKey: rootKey,
      );
      await sink.flush();
      return result;
    } on AppException {
      failed = true;
      rethrow;
    } finally {
      await sink.close();
      if (failed && destination.existsSync()) {
        destination.deleteSync();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Détails du format
  // ---------------------------------------------------------------------------

  /// Nonce de 12 octets : position du bloc (8) + marqueur de dernier bloc (4).
  /// La clé étant unique par fichier, un compteur suffit.
  static Uint8List _nonce(int blockIndex, bool isLast) => Bytes.concat([
    Bytes.uint64le(blockIndex),
    Bytes.uint32le(isLast ? 1 : 0),
  ]);

  /// Données authentifiées : l'en-tête complet, la position et le marqueur.
  static Uint8List _aad(Uint8List header, int blockIndex, bool isLast) =>
      Bytes.concat([
        header,
        Bytes.uint64le(blockIndex),
        Uint8List.fromList([isLast ? 1 : 0]),
      ]);

  /// Redécoupe un flux quelconque en blocs de taille fixe. Le dernier bloc
  /// (éventuellement vide) est marqué.
  static Stream<_Block> _reblock(Stream<List<int>> input, int size) async* {
    var pending = Uint8List(0);
    await for (final chunk in input) {
      var data = pending.isEmpty ? _asUint8(chunk) : Bytes.concat([pending, chunk]);
      // On garde toujours au moins un octet en attente, pour pouvoir marquer
      // le dernier bloc en voyant la fin du flux.
      while (data.length > size) {
        yield _Block(Uint8List.sublistView(data, 0, size), isLast: false);
        data = Uint8List.sublistView(data, size);
      }
      pending = data;
    }
    yield _Block(pending, isLast: true);
  }

  static Uint8List _asUint8(List<int> chunk) =>
      chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
}

final class _Block {
  const _Block(this.bytes, {required this.isLast});

  final Uint8List bytes;
  final bool isLast;
}

/// Lecture d'un flux par morceaux de taille exacte.
final class _ChunkReader {
  _ChunkReader(Stream<List<int>> input)
    : _iterator = StreamIterator<List<int>>(input);

  final StreamIterator<List<int>> _iterator;
  Uint8List _pending = Uint8List(0);
  bool _done = false;

  Future<bool> _fill() async {
    if (_done) {
      return false;
    }
    if (await _iterator.moveNext()) {
      final chunk = _iterator.current;
      _pending = _pending.isEmpty
          ? FileCipher._asUint8(chunk)
          : Bytes.concat([_pending, chunk]);
      return true;
    }
    _done = true;
    return false;
  }

  /// Lit exactement [n] octets, ou retourne `null` si le flux est trop court.
  Future<Uint8List?> readExactly(int n) async {
    while (_pending.length < n) {
      if (!await _fill()) {
        return null;
      }
    }
    final out = Uint8List.fromList(_pending.sublist(0, n));
    _pending = Uint8List.sublistView(_pending, n);
    return out;
  }

  /// Blocs chiffrés de [size] octets ; le dernier est plus court ou égal.
  Stream<_Block> blocks(int size) async* {
    while (true) {
      while (_pending.length <= size && await _fill()) {}
      if (_pending.length > size) {
        yield _Block(Uint8List.sublistView(_pending, 0, size), isLast: false);
        _pending = Uint8List.sublistView(_pending, size);
        continue;
      }
      // Fin du flux : ce qui reste est le dernier bloc.
      if (_pending.isNotEmpty) {
        yield _Block(_pending, isLast: true);
        _pending = Uint8List(0);
      }
      await _iterator.cancel();
      return;
    }
  }
}

/// Empreinte SHA-256 calculée au fil de l'eau (paquet `crypto`).
final class _Sha256Accumulator {
  _Sha256Accumulator();

  // Les deux puits sont fermés dans [close].
  // ignore: close_sinks
  final _DigestSink _output = _DigestSink();

  // ignore: close_sinks
  late final ByteConversionSink _sink = crypto.sha256.startChunkedConversion(
    _output,
  );

  void add(List<int> data) => _sink.add(data);

  Uint8List close() {
    _sink.close();
    return Uint8List.fromList(_output.digest!.bytes);
  }
}

final class _DigestSink implements Sink<crypto.Digest> {
  crypto.Digest? digest;

  @override
  void add(crypto.Digest data) => digest = data;

  @override
  void close() {}
}
