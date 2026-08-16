import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Dessine un ballon de football stylisé (repère 108x108), recadré au Size demandé.
class SportBallPainter extends CustomPainter {
  final Color outline;
  final Color fill;
  final Color accent;

  const SportBallPainter({
    this.outline = Colors.white,
    this.fill = const Color(0xFF0A0E0A),
    this.accent = const Color(0xFF00E676),
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 108.0, size.height / 108.0);

    final center = const Offset(54, 54);

    // Cercle extérieur (couture)
    canvas.drawCircle(center, 40, Paint()..color = outline);

    // Remplissage du ballon
    canvas.drawCircle(center, 36, Paint()..color = fill);

    // Pentagone central (accent)
    final pent = Path();
    const r = 14.0;
    for (int i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * (2 * math.pi / 5);
      final p = Offset(54 + r * math.cos(a), 54 + r * math.sin(a));
      if (i == 0) pent.moveTo(p.dx, p.dy);
      else pent.lineTo(p.dx, p.dy);
    }
    pent.close();
    canvas.drawPath(pent, Paint()..color = accent);

    // Coutures vers l'extérieur
    final stitch = Paint()
      ..color = outline
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * (2 * math.pi / 5);
      final inner = Offset(54 + r * math.cos(a), 54 + r * math.sin(a));
      final outer = Offset(54 + 33 * math.cos(a), 54 + 33 * math.sin(a));
      canvas.drawLine(inner, outer, stitch);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
