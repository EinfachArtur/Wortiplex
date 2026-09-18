import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/game_style.dart';
import '../../../domain/economy/spin_wheel.dart';

Color prizeColor(PrizeKind kind) => switch (kind) {
      PrizeKind.coins => const Color(0xFFF58E7E),
      PrizeKind.hint => const Color(0xFFF7961F),
      PrizeKind.strikeout => const Color(0xFFD98CF2),
      PrizeKind.skip => const Color(0xFF4DB9E3),
      PrizeKind.spin => const Color(0xFF2F9E94),
    };

IconData prizeIcon(PrizeKind kind) => switch (kind) {
      PrizeKind.coins => Icons.monetization_on_rounded,
      PrizeKind.hint => Icons.search_rounded,
      PrizeKind.strikeout => Icons.gps_fixed_rounded,
      PrizeKind.skip => Icons.skip_next_rounded,
      PrizeKind.spin => Icons.autorenew_rounded,
    };

/// Paints the prize wheel. Wedge 0 starts at the top and wedges run clockwise;
/// [rotation] turns the whole wheel clockwise (radians).
class WheelPainter extends CustomPainter {
  final List<SpinPrize> wedges;
  final double rotation;
  final double pulse; // 0..1, drives the blinking rim lights

  WheelPainter({required this.wedges, required this.rotation, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.width / 2;
    final rim = outer * 0.085;
    final inner = outer - rim;
    final w = 2 * math.pi / wedges.length;

    // Drop shadow + white rim.
    canvas.drawCircle(c + const Offset(0, 6), outer, Paint()..color = Colors.black26..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawCircle(c, outer, Paint()..color = const Color(0xFFF4F4F4));

    // Wedges.
    for (var i = 0; i < wedges.length; i++) {
      final start = rotation + i * w - math.pi / 2;
      final rect = Rect.fromCircle(center: c, radius: inner);
      final base = prizeColor(wedges[i].kind);
      canvas.drawArc(
        rect,
        start,
        w,
        true,
        Paint()
          ..shader = RadialGradient(
            colors: [Color.lerp(base, Colors.white, 0.18)!, base],
            stops: const [0.15, 1],
          ).createShader(rect),
      );
    }

    // Separators.
    final sep = Paint()
      ..color = const Color(0xFFF4F4F4)
      ..strokeWidth = outer * 0.022;
    for (var i = 0; i < wedges.length; i++) {
      final a = rotation + i * w - math.pi / 2;
      canvas.drawLine(c, c + Offset(math.cos(a), math.sin(a)) * inner, sep);
    }

    // Prize contents.
    for (var i = 0; i < wedges.length; i++) {
      final mid = rotation + (i + 0.5) * w - math.pi / 2;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(mid + math.pi / 2);
      canvas.translate(0, -inner * 0.66);
      _paintPrize(canvas, wedges[i], outer);
      canvas.restore();
    }

    // Rim lights.
    const lights = 24;
    for (var i = 0; i < lights; i++) {
      final a = i * 2 * math.pi / lights;
      final glow = i.isEven ? pulse : 1 - pulse;
      final p = c + Offset(math.cos(a), math.sin(a)) * (inner + rim / 2);
      canvas.drawCircle(p, rim * 0.95, Paint()
        ..color = GameColors.goldLight.withValues(alpha: 0.18 + 0.4 * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawCircle(p, rim * 0.34, Paint()..color = Color.lerp(const Color(0xFFE9D9A0), const Color(0xFFFFE9A0), glow)!);
    }

    // Hub.
    final hub = inner * 0.2;
    canvas.drawCircle(c, hub * 1.35, Paint()..color = const Color(0xFFF4F4F4));
    canvas.drawCircle(c, hub, Paint()..color = const Color(0xFFE879B6));
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rotation);
    _text(canvas, 'W', hub * 1.25, const Color(0xFFF7B5D8), Offset.zero);
    canvas.restore();
  }

  void _paintPrize(Canvas canvas, SpinPrize prize, double outer) {
    final iconSize = outer * 0.17;
    if (prize.kind == PrizeKind.coins) {
      // A little gold coin.
      final r = iconSize * 0.62;
      const center = Offset(0, -6);
      canvas.drawCircle(center + const Offset(0, 2), r, Paint()..color = Colors.black26);
      canvas.drawCircle(center, r, Paint()..shader = const LinearGradient(colors: [GameColors.goldLight, GameColors.gold])
          .createShader(Rect.fromCircle(center: center, radius: r)));
      canvas.drawCircle(center, r, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFB87400));
      _text(canvas, 'W', r * 1.15, const Color(0xFFFFF4C2), center);
    } else {
      _icon(canvas, prizeIcon(prize.kind), iconSize * 1.25, const Offset(0, -6));
    }
    _outlined(canvas, '+${prize.amount}', outer * 0.105, const Offset(0, 24));
  }

  void _icon(Canvas canvas, IconData icon, double size, Offset center) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(fontSize: size, fontFamily: icon.fontFamily, package: icon.fontPackage, color: Colors.white, shadows: const [
          Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 2)),
        ]),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _text(Canvas canvas, String text, double size, Color color, Offset center) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontFamily: kGameFont, fontSize: size, color: color, height: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _outlined(Canvas canvas, String text, double size, Offset center) {
    final style = TextStyle(fontFamily: kGameFont, fontSize: size, height: 1);
    final stroke = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = size / 4.5
            ..strokeJoin = StrokeJoin.round
            ..color = const Color(0xFF3B2A00),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final fill = TextPainter(
      text: TextSpan(text: text, style: style.copyWith(color: const Color(0xFFFFE04A))),
      textDirection: TextDirection.ltr,
    )..layout();
    final o = center - Offset(fill.width / 2, fill.height / 2);
    stroke.paint(canvas, o);
    fill.paint(canvas, o);
  }

  @override
  bool shouldRepaint(covariant WheelPainter old) => old.rotation != rotation || old.pulse != pulse;
}
