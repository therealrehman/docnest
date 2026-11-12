import 'package:flutter/material.dart';

import '../../app/motion/motion_tokens.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';

/// Primary action button (blueprint section 6): blue-to-cyan gradient,
/// press scale to 0.97 over 100ms, loading state, and a muted disabled state.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  bool get _active => widget.onPressed != null;
  bool get _interactive => _active && !widget.isLoading;

  void _setPressed(bool value) {
    if (_interactive && _pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final radius = BorderRadius.circular(DocNestSpacing.radiusButton);

    final activeDecoration = BoxDecoration(
      gradient: LinearGradient(
        colors: [DocNestColors.primaryBlue, palette.accentCyan],
      ),
      borderRadius: radius,
      boxShadow: [
        BoxShadow(
          color: DocNestColors.primaryBlue.withValues(alpha: 0.25),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
    final disabledDecoration = BoxDecoration(
      color: palette.secondarySurface,
      borderRadius: radius,
      border: Border.all(color: palette.border),
    );

    final content = widget.isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
          )
        : Text(
            widget.label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: _active ? Colors.white : palette.textMuted,
            ),
          );

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _interactive ? widget.onPressed : null,
        child: SizedBox(
          height: DocNestSpacing.buttonHeight,
          child: Center(child: content),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: _interactive,
      label: widget.label,
      child: SizedBox(
        width: widget.fullWidth ? double.infinity : null,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: MotionTokens.resolve(context, MotionTokens.buttonPress),
          curve: MotionTokens.buttonFeedback,
          child: AnimatedContainer(
            duration: MotionTokens.resolve(context, MotionTokens.smallFade),
            decoration: _active ? activeDecoration : disabledDecoration,
            child: button,
          ),
        ),
      ),
    );
  }
}
