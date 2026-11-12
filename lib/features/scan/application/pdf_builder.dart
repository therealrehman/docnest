import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/scan_page.dart';

/// Longest side of a page image in pixels. Enough to read small print, small enough for a phone.
const _maxSidePx = 1800;
const _jpegQuality = 85;

/// Builds one A4 page per scan, in order, and returns the PDF bytes.
///
/// Decoding and encoding camera photos is slow, so the work runs in a background
/// isolate (compute) to keep the UI responsive.
Future<Uint8List> buildScanPdf(List<ScanPage> pages) {
  final jobs = [
    for (final page in pages) _PageJob(path: page.path, quarterTurns: page.quarterTurns),
  ];
  return compute(_buildPdfInBackground, jobs);
}

/// Plain data only, so it can be sent to the background isolate.
class _PageJob {
  const _PageJob({required this.path, required this.quarterTurns});

  final String path;
  final int quarterTurns;
}

Future<Uint8List> _buildPdfInBackground(List<_PageJob> jobs) async {
  final document = pw.Document();
  for (final job in jobs) {
    final image = pw.MemoryImage(_prepareJpeg(job));
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(18),
        build: (context) => pw.Center(
          child: pw.Image(image, fit: pw.BoxFit.contain),
        ),
      ),
    );
  }
  return document.save();
}

/// Reads one photo, applies EXIF orientation and the user's rotation,
/// shrinks it when it is very large, and encodes it as JPEG.
Uint8List _prepareJpeg(_PageJob job) {
  final decoded = img.decodeImage(File(job.path).readAsBytesSync());
  if (decoded == null) {
    throw const FormatException('A scanned page could not be read.');
  }

  var image = img.bakeOrientation(decoded);
  if (job.quarterTurns != 0) {
    image = img.copyRotate(image, angle: job.quarterTurns * 90);
  }

  final isLandscape = image.width > image.height;
  final longest = isLandscape ? image.width : image.height;
  if (longest > _maxSidePx) {
    image = isLandscape
        ? img.copyResize(image, width: _maxSidePx)
        : img.copyResize(image, height: _maxSidePx);
  }

  return img.encodeJpg(image, quality: _jpegQuality);
}
