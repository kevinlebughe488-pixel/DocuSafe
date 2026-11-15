import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:docusafe/core/errors/app_exception.dart';
import 'package:docusafe/core/security/crypto/dart_crypto_engine.dart';
import 'package:docusafe/core/security/crypto/dsf_header.dart';
import 'package:docusafe/core/security/crypto/file_cipher.dart';
import 'package:docusafe/core/utils/bytes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests du format DSF1 (docs/04-securite.md §8 et §20).
void main() {
  const engine = DartCryptoEngine();
  final cipher = FileCipher(engine);
  final rootKey = Uint8List.fromList(List.generate(32, (i) => i));
  final otherKey = Uint8List.fromList(List.generate(32, (i) => 255 - i));

  // Petits blocs pour tester plusieurs blocs sans gros fichiers.
  const blockSize = 4096;

  Uint8List sample(int length) =>
      Uint8List.fromList(List.generate(length, (i) => (i * 31 + 7) & 0xff));

  group('aller-retour', () {
    for (final length in [0, 1, 4095, 4096, 4097, 3 * 4096, 10000]) {
      test('$length octets', () async {
        final plain = sample(length);
        final encrypted = await cipher.encryptBytes(
          plaintext: plain,
          rootKey: rootKey,
          blockSize: blockSize,
        );
        expect(encrypted.length, greaterThanOrEqualTo(DsfHeader.length + 16));
        // Le début du fichier chiffré ne contient pas le clair.
        if (length > 32) {
          expect(
            String.fromCharCodes(encrypted).contains(
              String.fromCharCodes(plain.sublist(0, 32)),
            ),
            isFalse,
          );
        }
        final (decrypted, result) = await cipher.decryptBytes(
          ciphertext: encrypted,
          rootKey: rootKey,
        );
        expect(decrypted, plain);
        expect(result.plainLength, length);
        expect(result.sha256, crypto.sha256.convert(plain).bytes);
      });
    }
  });

  test('deux chiffrements du même contenu diffèrent (sel unique)', () async {
    final plain = sample(100);
    final a = await cipher.encryptBytes(plaintext: plain, rootKey: rootKey);
    final b = await cipher.encryptBytes(plaintext: plain, rootKey: rootKey);
    expect(a, isNot(equals(b)));
  });

  test('mauvaise clé → erreur d\'intégrité', () async {
    final encrypted = await cipher.encryptBytes(
      plaintext: sample(500),
      rootKey: rootKey,
    );
    await expectLater(
      cipher.decryptBytes(ciphertext: encrypted, rootKey: otherKey),
      throwsA(same(CryptoException.integrity)),
    );
  });

  test('octet modifié → erreur d\'intégrité', () async {
    final encrypted = await cipher.encryptBytes(
      plaintext: sample(3 * blockSize),
      rootKey: rootKey,
      blockSize: blockSize,
    );
    for (final offset in [DsfHeader.length + 10, encrypted.length - 1, 12]) {
      final tampered = Uint8List.fromList(encrypted);
      tampered[offset] ^= 0x01;
      await expectLater(
        cipher.decryptBytes(ciphertext: tampered, rootKey: rootKey),
        throwsA(same(CryptoException.integrity)),
        reason: 'offset $offset',
      );
    }
  });

  test('fichier tronqué → erreur d\'intégrité', () async {
    const header = DsfHeader.length;
    const encBlock = blockSize + 16;
    final encrypted = await cipher.encryptBytes(
      plaintext: sample(3 * blockSize),
      rootKey: rootKey,
      blockSize: blockSize,
    );
    // Tronqué au milieu d'un bloc et exactement à une frontière de bloc.
    for (final cut in [header + encBlock + 100, header + 2 * encBlock]) {
      await expectLater(
        cipher.decryptBytes(
          ciphertext: Uint8List.sublistView(encrypted, 0, cut),
          rootKey: rootKey,
        ),
        throwsA(same(CryptoException.integrity)),
        reason: 'cut $cut',
      );
    }
  });

  test('blocs échangés → erreur d\'intégrité', () async {
    const header = DsfHeader.length;
    const encBlock = blockSize + 16;
    final encrypted = await cipher.encryptBytes(
      plaintext: sample(3 * blockSize),
      rootKey: rootKey,
      blockSize: blockSize,
    );
    final swapped = Uint8List.fromList(encrypted);
    swapped.setRange(
      header,
      header + encBlock,
      encrypted.sublist(header + encBlock, header + 2 * encBlock),
    );
    swapped.setRange(
      header + encBlock,
      header + 2 * encBlock,
      encrypted.sublist(header, header + encBlock),
    );
    await expectLater(
      cipher.decryptBytes(ciphertext: swapped, rootKey: rootKey),
      throwsA(same(CryptoException.integrity)),
    );
  });

  test('en-tête inconnu → mauvais format', () async {
    final bogus = Uint8List.fromList([...'PDF-'.codeUnits, ...sample(100)]);
    await expectLater(
      cipher.decryptBytes(ciphertext: bogus, rootKey: rootKey),
      throwsA(same(CryptoException.badFormat)),
    );
    await expectLater(
      cipher.decryptBytes(ciphertext: Uint8List(10), rootKey: rootKey),
      throwsA(same(CryptoException.badFormat)),
    );
  });

  test('fichiers : chiffrement puis déchiffrement sur disque', () async {
    final dir = await Directory.systemTemp.createTemp('dsf_test');
    try {
      final plain = sample(2 * 1024 * 1024 + 123);
      final source = File('${dir.path}/in.bin')..writeAsBytesSync(plain);
      final encrypted = File('${dir.path}/out.dsf');
      final restored = File('${dir.path}/back.bin');

      final result = await cipher.encryptFile(
        source: source,
        destination: encrypted,
        rootKey: rootKey,
      );
      expect(result.plainLength, plain.length);
      expect(encrypted.lengthSync(), DsfHeader.length + plain.length + 3 * 16);

      final back = await cipher.decryptFile(
        source: encrypted,
        destination: restored,
        rootKey: rootKey,
      );
      expect(back.sha256Hex, result.sha256Hex);
      expect(restored.readAsBytesSync(), plain);

      // Mauvaise clé : la destination est supprimée.
      await expectLater(
        cipher.decryptFile(
          source: encrypted,
          destination: restored,
          rootKey: otherKey,
        ),
        throwsA(same(CryptoException.integrity)),
      );
      expect(restored.existsSync(), isFalse);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('en-tête : encodage et décodage', () {
    final salt = Uint8List.fromList(List.generate(16, (i) => i * 3));
    final header = DsfHeader(blockSize: 1024 * 1024, salt: salt);
    final bytes = header.encode();
    expect(bytes.length, 32);
    expect(String.fromCharCodes(bytes.sublist(0, 4)), 'DSF1');
    final decoded = DsfHeader.decode(bytes);
    expect(decoded.blockSize, 1024 * 1024);
    expect(decoded.salt, salt);

    final future = Uint8List.fromList(bytes)..[4] = 2;
    expect(
      () => DsfHeader.decode(future),
      throwsA(same(CryptoException.unsupportedVersion)),
    );
  });

  test('utilitaires octets', () {
    expect(Bytes.constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
    expect(Bytes.constantTimeEquals([1, 2, 3], [1, 2, 4]), isFalse);
    expect(Bytes.constantTimeEquals([1, 2], [1, 2, 3]), isFalse);
    expect(Bytes.toHex([0, 255, 16]), '00ff10');
    final data = Uint8List.fromList([1, 2, 3]);
    Bytes.wipe(data);
    expect(data, [0, 0, 0]);
  });
}
