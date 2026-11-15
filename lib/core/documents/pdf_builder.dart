import 'dart:io';
import 'dart:isolate';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Assemble des pages scannées (images JPEG ou PNG) en un seul PDF
/// (cahier des charges §3.3 : « conversion en PDF »).
///
/// Chaque page garde les proportions de son image, sur une largeur A4.
/// Le calcul s'exécute dans un isolate (docs/02-architecture.md §8).
abstract final class PdfBuilder {
  static Future<void> fromImages(List<File> pages, File output) {
    final paths = [for (final p in pages) p.path];
    final out = output.path;
    return Isolate.run(() async {
      final doc = pw.Document(creator: 'DocSafe', producer: 'DocSafe');
      for (final path in paths) {
        final image = pw.MemoryImage(File(path).readAsBytesSync());
        final width = PdfPageFormat.a4.width;
        final ratio = (image.height ?? 1) / (image.width ?? 1);
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(width, width * ratio),
            margin: pw.EdgeInsets.zero,
            build: (_) => pw.Image(image, fit: pw.BoxFit.fill),
          ),
        );
      }
      await File(out).writeAsBytes(await doc.save(), flush: true);
    }, debugName: 'pdf.build');
  }
}
