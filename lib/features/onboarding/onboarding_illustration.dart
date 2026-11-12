import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';

/// Canvas size shared by the three onboarding illustrations.
const onboardingIllustrationSize = Size(260, 200);

/// On-brand onboarding illustrations drawn with Canvas. No image assets needed.
/// Page 0: documents moving into a folder.
/// Page 1: calendar with a document and an alert badge.
/// Page 2: folder with a shield and lock.
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({super.key, required this.page});

  final int page;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox(
      width: onboardingIllustrationSize.width,
      height: onboardingIllustrationSize.height,
      child: CustomPaint(
        painter: _IllustrationPainter(
          page: page,
          primary: DocNestColors.primaryBlue,
          accent: palette.accentCyan,
          paper: palette.elevatedSurface,
          line: palette.border,
        ),
      ),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  _IllustrationPainter({
    required this.page,
    required this.primary,
    required this.accent,
    required this.paper,
    required this.line,
  });

  final int page;
  final Color primary;
  final Color accent;
  final Color paper;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    if (page == 0) {
      _documentsIntoFolder(canvas);
    } else if (page == 1) {
      _datesAndAlerts(canvas);
    } else {
      _privacyShield(canvas);
    }
  }

  void _documentsIntoFolder(Canvas canvas) {
    _drawDocument(canvas, Rect.fromLTWH(26, 8, 70, 88), -0.22);
    _drawDocument(canvas, Rect.fromLTWH(96, 2, 70, 88), 0.04);
    _drawDocument(canvas, Rect.fromLTWH(164, 12, 70, 88), 0.24);
    _drawFolder(canvas, Rect.fromLTWH(40, 96, 180, 98), primary);
  }

  void _datesAndAlerts(Canvas canvas) {
    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(24, 36, 150, 140),
      const Radius.circular(16),
    );
    canvas.drawRRect(card, Paint()..color = paper);
    canvas.drawRRect(
      card,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final header = RRect.fromRectAndCorners(
      Rect.fromLTWH(24, 36, 150, 36),
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
    );
    canvas.drawRRect(header, Paint()..color = primary);

    final cell = Paint()..color = line;
    final highlight = Paint()..color = accent;
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 5; col++) {
        final rect = Rect.fromLTWH(44.0 + col * 26, 92.0 + row * 26, 14, 14);
        final isHighlighted = row == 1 && col == 2;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          isHighlighted ? highlight : cell,
        );
      }
    }

    _drawDocument(canvas, Rect.fromLTWH(150, 4, 84, 100), 0.14);

    canvas.drawCircle(const Offset(214, 164), 24, Paint()..color = accent);
    canvas.drawCircle(const Offset(214, 164), 6, Paint()..color = paper);
  }

  void _privacyShield(Canvas canvas) {
    _drawFolder(canvas, Rect.fromLTWH(30, 88, 200, 108), primary);

    final shield = _shieldPath(Rect.fromLTWH(86, 14, 88, 104));
    canvas.drawPath(shield, Paint()..color = accent);

    final lockBody = RRect.fromRectAndRadius(
      Rect.fromLTWH(118, 66, 24, 22),
      const Radius.circular(5),
    );
    canvas.drawRRect(lockBody, Paint()..color = paper);

    final shackle = Paint()
      ..color = paper
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromLTWH(122, 46, 16, 24), math.pi, math.pi, false, shackle);
  }

  void _drawDocument(Canvas canvas, Rect rect, double angle) {
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(angle);
    canvas.translate(-rect.width / 2, -rect.height / 2);

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, rect.width, rect.height),
      const Radius.circular(10),
    );
    canvas.drawRRect(body, Paint()..color = paper);
    canvas.drawRRect(
      body,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final bar = Paint()..color = line;
    for (var i = 0; i < 3; i++) {
      final width = rect.width - 24 - (i == 2 ? 14 : 0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(12, 20.0 + i * 14, width, 5),
          const Radius.circular(3),
        ),
        bar,
      );
    }

    canvas.restore();
  }

  void _drawFolder(Canvas canvas, Rect rect, Color color) {
    final tab = RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.left, rect.top, rect.width * 0.42, rect.height * 0.26),
      const Radius.circular(12),
    );
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        rect.left,
        rect.top + rect.height * 0.16,
        rect.width,
        rect.height * 0.84,
      ),
      const Radius.circular(16),
    );
    canvas.drawRRect(tab, Paint()..color = color.withValues(alpha: 0.7));
    canvas.drawRRect(body, Paint()..color = color);
  }

  Path _shieldPath(Rect r) {
    return Path()
      ..moveTo(r.center.dx, r.top)
      ..quadraticBezierTo(r.right, r.top + r.height * 0.08, r.right, r.top + r.height * 0.42)
      ..quadraticBezierTo(r.right, r.bottom - r.height * 0.12, r.center.dx, r.bottom)
      ..quadraticBezierTo(r.left, r.bottom - r.height * 0.12, r.left, r.top + r.height * 0.42)
      ..quadraticBezierTo(r.left, r.top + r.height * 0.08, r.center.dx, r.top)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _IllustrationPainter oldDelegate) {
    return oldDelegate.page != page ||
        oldDelegate.primary != primary ||
        oldDelegate.accent != accent ||
        oldDelegate.paper != paper ||
        oldDelegate.line != line;
  }
}
