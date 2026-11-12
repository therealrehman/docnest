import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'documents_controller.dart';

/// Opens the file picker and shows the result. Shared by Home, the Documents tab and the add sheet.
Future<void> runImport(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final summary = await ref.read(documentsProvider.notifier).importFromPicker();
    messenger.showSnackBar(SnackBar(content: Text(_summaryText(summary))));
  } on Exception {
    messenger.showSnackBar(
      const SnackBar(content: Text('Import failed. Please try again.')),
    );
  }
}

String _summaryText(ImportSummary summary) {
  if (summary.imported == 0 && summary.skipped == 0 && summary.duplicates == 0) {
    return 'No file selected.';
  }
  if (summary.imported == 0 && summary.duplicates == 0) {
    return 'Only PDF and image files can be imported.';
  }

  final parts = <String>[];
  if (summary.imported > 0) {
    final count = summary.imported == 1 ? '1 file' : '${summary.imported} files';
    parts.add('Imported $count.');
  }
  if (summary.duplicates > 0) {
    parts.add(
      summary.duplicates == 1
          ? '1 was already in DocNest, skipped.'
          : '${summary.duplicates} were already in DocNest, skipped.',
    );
  }
  if (summary.skipped > 0) {
    parts.add('${summary.skipped} unsupported skipped.');
  }
  return parts.join(' ');
}
