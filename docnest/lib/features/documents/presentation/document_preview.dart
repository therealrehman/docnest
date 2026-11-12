import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../data/document_record.dart';

/// Preview of an imported file on a dark neutral background.
/// Images zoom with pinch. PDFs scroll page by page and zoom.
class DocumentPreview extends StatefulWidget {
  const DocumentPreview({super.key, required this.record, required this.file});

  final DocumentRecord record;
  final File file;

  @override
  State<DocumentPreview> createState() => _DocumentPreviewState();
}

class _DocumentPreviewState extends State<DocumentPreview> {
  PdfController? _pdfController;

  @override
  void initState() {
    super.initState();
    if (widget.record.kind == DocumentKind.pdf) {
      _pdfController = PdfController(
        document: PdfDocument.openFile(widget.file.path),
      );
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _pdfController;

    return ColoredBox(
      color: DocNestColors.darkBackground,
      child: controller != null
          ? PdfView(controller: controller)
          : InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: Image.file(
                  widget.file,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Padding(
                    padding: EdgeInsets.all(DocNestSpacing.section),
                    child: Text(
                      'This file could not be displayed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: DocNestColors.darkTextSecondary),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
