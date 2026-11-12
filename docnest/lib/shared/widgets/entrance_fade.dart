import 'package:flutter/material.dart';

import '../../app/motion/motion_tokens.dart';

/// Plays a one-time fade + 8px rise on first appearance (blueprint section 19).
/// Lives in State, so it does not replay on every parent rebuild.
class EntranceFade extends StatefulWidget {
  const EntranceFade({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<EntranceFade> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: MotionTokens.cardAppearance,
  );

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await Future<void>.delayed(widget.delay);
    if (!mounted) return;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = MotionTokens.entrance.transform(_controller.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}
