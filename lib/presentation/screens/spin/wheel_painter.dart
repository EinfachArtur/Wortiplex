import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/game_style.dart';
import '../../../domain/economy/spin_wheel.dart';

Color prizeColor(PrizeKind kind) => switch (kind) {
      PrizeKind.coins => const Color(0xFFFFB13B),
      PrizeKind.hint => const Color(0xFF8B6CFF),
      PrizeKind.strikeout => const Color(0xFFFF6B8E),
      PrizeKind.skip => const Color(0xFF1FC7B0),
      PrizeKind.spin => const Color(0xFF4DA8FF),
    };

IconData prizeIcon(PrizeKind kind) => switch (kind) {
      PrizeKind.coins => Icons.star_rounded,
      PrizeKind.hint => Icons.lightbulb_rounded,
      PrizeKind.strikeout => Icons.block_rounded,
      PrizeKind.skip => Icons.fast_forward_rounded,
      PrizeKind.spin => Icons.confirmation_number_rounded,
    };

/// Paints the prize wheel. Wedge 0 starts at the top and wedges run
/// clockwise; [rotation] turns the wheel clockwise (radians). Prize badges stay
/// upright while the wheel turns so they are always easy to read.
class WheelPainter extends CustomPainter {
  final List<SpinPrize> wedges;
  final double rotation;
  final double pulse; // 0..1, drives the blinking ring studs

  WheelPainter({required this.wedges, required this.rotation, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.width / 2;
    final ringW = outer * 0.115;
    final inner = outer - ringW;
    final w = 2 * math.pi / wedges.length;

    // Shadow and ring.
    canvas.drawCircle(c + const Offset(0, 8), outer, Paint()
      ..color = const Color(0x66000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
    canvas.drawCircle(c, outer, Paint()..color = GameColors.ring);
    canvas.drawCircle(c, outer - 1.5, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = GameColors.amber);
    canvas.drawCircle(c, inner + 1.5, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0x55FFFFFF));

    // Wedges.
    final rect = Rect.fromCircle(center: c, radius: inner);
    for (var i = 0; i < wedges.length; i++) {
      final base = prizeColor(wedges[i].kind);
      canvas.drawArc(
        rect,
        rotation + i * w - math.pi / 2,
        w,
        true,
        Paint()
          ..shader = RadialGradient(
            colors: [Color.lerp(base, Colors.white, 0.28)!, base, Color.lerp(base, Colors.black, 0.18)!],
            stops: const [0.1, 0.62, 1],
          ).createShader(rect),
      );
    }
    final sep = Paint()
      ..color = GameColors.ring
      ..strokeWidth = outer * 0.02;
    for (var i = 0; i < wedges.length; i++) {
      final a = rotation + i * w - math.pi / 2;
      canvas.drawLine(c, c + Offset(math.cos(a), math.sin(a)) * inner, sep);
    }

    // Prize badges (upright).
    for (var i = 0; i < wedges.length; i++) {
      final mid = rotation + (i + 0.5) * w - math.pi / 2;
      final p = c + Offset(math.cos(mid), math.sin(mid)) * inner * 0.64;
      _paintPrize(canvas, wedges[i], p, inner);
    }

    // Ring studs.
    const studs = 16;
    for (var i = 0; i < studs; i++) {
      final a = i * 2 * math.pi / studs;
      final glow = i.isEven ? pulse : 1 - pulse;
      final p = c + Offset(math.cos(a), math.sin(a)) * (inner + ringW / 2);
      final color = i.isEven ? GameColors.mint : GameColors.amber;
      canvas.drawCircle(p, ringW * 0.62, Paint()
        ..color = color.withValues(alpha: 0.10 + 0.32 * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawCircle(p, ringW * 0.2, Paint()..color = Color.lerp(color.withValues(alpha: 0.5), color, glow)!);
    }

    // Hub with a turning star.
    final hub = inner * 0.19;
    canvas.drawCircle(c, hub * 1.28, Paint()..color = GameColors.ring);
    canvas.drawCircle(c, hub * 1.28, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = GameColors.amber);
    canvas.drawCircle(c, hub, Paint()..color = const Color(0xFF3A2A8C));
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rotation);
    canvas.drawPath(starPath(Offset.zero, hub * 0.82, hub * 0.38), Paint()..color = GameColors.amberLight);
    canvas.restore();
  }

  void _paintPrize(Canvas canvas, SpinPrize prize, Offset center, double inner) {
    final r = inner * 0.15;
    final badge = center + Offset(0, -r * 0.35);

    if (prize.kind == PrizeKind.coins) {
      canvas.drawCircle(badge + const Offset(0, 2.5), r, Paint()..color = const Color(0x40000000));
      canvas.drawCircle(badge, r, Paint()
        ..shader = const LinearGradient(colors: [GameColors.amberLight, GameColors.amber, Color(0xFFE8920A)])
            .createShader(Rect.fromCircle(center: badge, radius: r)));
      canvas.drawCircle(badge, r, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.16
        ..color = const Color(0xFFC77A00));
      canvas.drawPath(starPath(badge, r * 0.56, r * 0.26), Paint()..color = const Color(0xFFFFF6D6));
    } else {
      canvas.drawCircle(badge + const Offset(0, 2.5), r, Paint()..color = const Color(0x40000000));
      canvas.drawCircle(badge, r, Paint()..color = Colors.white);
      _icon(canvas, prizeIcon(prize.kind), r * 1.25, badge, Color.lerp(prizeColor(prize.kind), Colors.black, 0.25)!);
    }

    final label = TextPainter(
      text: TextSpan(text: '+${prize.amount}', style: gameText(inner * 0.1, shadowColor: const Color(0x80000000))),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, center + Offset(-label.width / 2, r * 0.78));
  }

  void _icon(Canvas canvas, IconData icon, double size, Offset center, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(fontSize: size, fontFamily: icon.fontFamily, package: icon.fontPackage, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant WheelPainter old) => old.rotation != rotation || old.pulse != pulse;
}

/// The wheel's pointer: a golden drop pointing down into the wheel.
class PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, h)
      ..lineTo(w * 0.06, h * 0.34)
      ..quadraticBezierTo(w * 0.0, h * 0.02, w * 0.5, 0)
      ..quadraticBezierTo(w * 1.0, h * 0.02, w * 0.94, h * 0.34)
      ..close();
    canvas.drawPath(path.shift(const Offset(0, 3)), Paint()
      ..color = const Color(0x66000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawPath(path, Paint()
      ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [GameColors.amberLight, GameColors.amber])
          .createShader(Offset.zero & size));
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..color = GameColors.ring);
    canvas.drawCircle(Offset(w * 0.5, h * 0.33), w * 0.17, Paint()..color = GameColors.mint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.33), w * 0.17, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = GameColors.ring);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
