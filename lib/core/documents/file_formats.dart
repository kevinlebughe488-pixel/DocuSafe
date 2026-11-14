import 'dart:io';
import 'dart:typed_data';

import '../database/tables.dart';

/// Formats de fichier acceptés (docs/02-architecture.md §12 : liste
/// centralisée, extensible). Le type est reconnu par la **signature** du
/// contenu, jamais par l'extension seule.
final class FileFormat {
  const FileFormat({
    required this.type,
    required this.label,
    required this.extensions,
    required this.mimeType,
    required this.signatures,
  });

  final DocumentFileType type;

  /// Nom affiché : « PDF », « JPEG », « PNG ».
  final String label;
  final List<String> extensions;
  final String mimeType;

  /// Premiers octets possibles du fichier.
  final List<List<int>> signatures;

  String get defaultExtension => extensions.first;
}

abstract final class FileFormats {
  static const List<FileFormat> all = [
    FileFormat(
      type: DocumentFileType.pdf,
      label: 'PDF',
      extensions: ['pdf'],
      mimeType: 'application/pdf',
      signatures: [
        [0x25, 0x50, 0x44, 0x46, 0x2D], // %PDF-
      ],
    ),
    FileFormat(
      type: DocumentFileType.jpeg,
      label: 'JPEG',
      extensions: ['jpg', 'jpeg'],
      mimeType: 'image/jpeg',
      signatures: [
        [0xFF, 0xD8, 0xFF],
      ],
    ),
    FileFormat(
      type: DocumentFileType.png,
      label: 'PNG',
      extensions: ['png'],
      mimeType: 'image/png',
      signatures: [
        [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
      ],
    ),
  ];

  /// Nombre d'octets suffisant pour reconnaître tous les formats.
  static const int sniffLength = 16;

  /// Extensions proposées au sélecteur de fichiers.
  static List<String> get pickerExtensions => [
    for (final f in all) ...f.extensions,
  ];

  static FileFormat of(DocumentFileType type) =>
      all.firstWhere((f) => f.type == type);

  /// Reconnaît le format d'après les premiers octets, ou `null`.
  static FileFormat? detect(List<int> head) {
    for (final format in all) {
      for (final sig in format.signatures) {
        if (head.length >= sig.length) {
          var match = true;
          for (var i = 0; i < sig.length; i++) {
            if (head[i] != sig[i]) {
              match = false;
              break;
            }
          }
          if (match) {
            return format;
          }
        }
      }
    }
    return null;
  }

  /// Lit le début du fichier et reconnaît son format, ou `null`.
  static Future<FileFormat?> detectFile(File file) async {
    final raf = await file.open();
    try {
      final head = await raf.read(sniffLength);
      return detect(Uint8List.fromList(head));
    } finally {
      await raf.close();
    }
  }

}

extension DocumentFileTypeX on DocumentFileType {
  bool get isImage => this != DocumentFileType.pdf;

  FileFormat get format => FileFormats.of(this);
}
