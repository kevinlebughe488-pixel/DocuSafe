import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart';

import '../config/app_config.dart';
import '../database/tables.dart';
import '../utils/app_log.dart';

/// Ce que l'on sait d'un fichier après l'avoir ouvert : nombre de pages et
/// miniature JPEG (au plus 512 px de côté), ou `null` si illisible.
final class FilePreview {
  const FilePreview({required this.thumbnailJpeg, required this.pageCount});

  final Uint8List? thumbnailJpeg;
  final int? pageCount;
}

/// Lecture d'un fichier pour en tirer une miniature et compter ses pages.
/// Derrière une interface : le lecteur PDF est un composant lourd
/// (docs/02-architecture.md, règle 3).
abstract interface class ThumbnailService {
  Future<FilePreview> preview(File source, DocumentFileType type);
}

/// Images : paquet `image` dans un isolate. PDF : moteur PDFium (pdfrx),
/// première page rendue en image. **À vérifier sur téléphone** pour la
/// vitesse sur les gros fichiers.
final class PlatformThumbnailService implements ThumbnailService {
  const PlatformThumbnailService();

  @override
  Future<FilePreview> preview(File source, DocumentFileType type) async {
    try {
      return switch (type) {
        DocumentFileType.pdf => await _previewPdf(source),
        DocumentFileType.jpeg || DocumentFileType.png => await _previewImage(
          source,
        ),
      };
    } on Object catch (e, s) {
      AppLog.error('thumbnail.failed', e, s);
      return const FilePreview(thumbnailJpeg: null, pageCount: null);
    }
  }

  static Future<FilePreview> _previewImage(File source) async {
    final path = source.path;
    final jpeg = await Isolate.run(() {
      final decoded = img.decodeImage(File(path).readAsBytesSync());
      if (decoded == null) {
        return null;
      }
      return _toThumbnailJpeg(img.bakeOrientation(decoded));
    }, debugName: 'thumbnail.image');
    return FilePreview(thumbnailJpeg: jpeg, pageCount: jpeg == null ? null : 1);
  }

  static Future<FilePreview> _previewPdf(File source) async {
    await pdfrxFlutterInitialize();
    final document = await PdfDocument.openFile(source.path);
    try {
      final pages = document.pages;
      if (pages.isEmpty) {
        return const FilePreview(thumbnailJpeg: null, pageCount: 0);
      }
      final page = pages.first;
      final scale = DocumentLimits.thumbnailMaxSide / (page.width > page.height ? page.width : page.height);
      final width = (page.width * scale).round();
      final height = (page.height * scale).round();
      final rendered = await page.render(
        width: width,
        height: height,
        fullWidth: width.toDouble(),
        fullHeight: height.toDouble(),
        backgroundColor: 0xFFFFFFFF,
      );
      if (rendered == null) {
        return FilePreview(thumbnailJpeg: null, pageCount: pages.length);
      }
      try {
        final pixels = Uint8List.fromList(rendered.pixels);
        final w = rendered.width;
        final h = rendered.height;
        final jpeg = await Isolate.run(() {
          final image = img.Image.fromBytes(
            width: w,
            height: h,
            bytes: pixels.buffer,
            numChannels: 4,
            order: img.ChannelOrder.bgra,
          );
          return _toThumbnailJpeg(image);
        }, debugName: 'thumbnail.pdf');
        return FilePreview(thumbnailJpeg: jpeg, pageCount: pages.length);
      } finally {
        rendered.dispose();
      }
    } finally {
      await document.dispose();
    }
  }

  static Uint8List _toThumbnailJpeg(img.Image image) {
    final longest = image.width > image.height ? image.width : image.height;
    var resized = image;
    if (longest > DocumentLimits.thumbnailMaxSide) {
      resized = image.width >= image.height
          ? img.copyResize(
              image,
              width: DocumentLimits.thumbnailMaxSide,
              interpolation: img.Interpolation.average,
            )
          : img.copyResize(
              image,
              height: DocumentLimits.thumbnailMaxSide,
              interpolation: img.Interpolation.average,
            );
    }
    // Les PNG transparents sont aplatis sur fond blanc.
    final flat = resized.numChannels == 4
        ? (img.Image(width: resized.width, height: resized.height)
            ..clear(img.ColorRgb8(255, 255, 255)))
        : null;
    final toEncode = flat == null
        ? resized
        : img.compositeImage(flat, resized);
    return img.encodeJpg(toEncode, quality: DocumentLimits.thumbnailJpegQuality);
  }
}

/// Version simulée : miniature fixe, nombre de pages fixe (tests).
final class FakeThumbnailService implements ThumbnailService {
  const FakeThumbnailService({this.thumbnail, this.pageCount = 1});

  final Uint8List? thumbnail;
  final int? pageCount;

  @override
  Future<FilePreview> preview(File source, DocumentFileType type) async =>
      FilePreview(thumbnailJpeg: thumbnail, pageCount: pageCount);
}

/// Miniatures d'images en Dart pur, sans PDF : utilisée dans les tests pour
/// vérifier la chaîne complète sur un PNG réel.
final class ImageOnlyThumbnailService implements ThumbnailService {
  const ImageOnlyThumbnailService();

  @override
  Future<FilePreview> preview(File source, DocumentFileType type) async {
    if (type == DocumentFileType.pdf) {
      return const FilePreview(thumbnailJpeg: null, pageCount: null);
    }
    return PlatformThumbnailService._previewImage(source);
  }
}
