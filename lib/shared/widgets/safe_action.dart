import 'package:flutter/material.dart';

/// Runs [action]. On a storage error, shows a message instead of failing silently.
Future<void> runSafely(
  BuildContext context,
  Future<void> Function() action, {
  String message = 'Could not save the change. Please try again.',
}) async {
  try {
    await action();
  } on Exception {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
