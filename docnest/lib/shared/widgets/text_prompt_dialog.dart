import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';

/// One-field dialog. Returns the typed text (not trimmed), or null when cancelled.
/// [message] is optional supporting text shown above the field.
Future<String?> showTextPrompt(
  BuildContext context, {
  required String title,
  String initialText = '',
  String? hint,
  String? message,
  String confirmLabel = 'Save',
  int? maxLength,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextPromptDialog(
      title: title,
      initialText: initialText,
      hint: hint,
      message: message,
      confirmLabel: confirmLabel,
      maxLength: maxLength,
    ),
  );
}

/// Owns its controller, so it is disposed only after the dialog is gone.
class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.initialText,
    required this.hint,
    required this.message,
    required this.confirmLabel,
    required this.maxLength,
  });

  final String title;
  final String initialText;
  final String? hint;
  final String? message;
  final String confirmLabel;
  final int? maxLength;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    final message = widget.message;

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message != null) ...[
            Text(message, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: DocNestSpacing.s),
          ],
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: widget.maxLength,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(hintText: widget.hint),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
