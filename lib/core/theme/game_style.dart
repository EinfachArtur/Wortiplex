import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Wortiplex "night sky" look: deep indigo, mint, coral and amber, with
/// glassy surfaces and sparkles. Used by the wheel and puzzle screens.
const kGameFont = 'Rubik';

class GameColors {
  const GameColors._();

  static const night0 = Color(0xFF130E3A);
  static const night1 = Color(0xFF2C1C6E);
  static const ring = Color(0xFF221860);
  static const glass = Color(0x1FFFFFFF);
  static const glassBorder = Color(0x2EFFFFFF);
  static const pill = Color(0x59000000);
  static const textDim = Color(0xB3FFFFFF);

  static const mint = Color(0xFF1FDDB8);
  static const mintDark = Color(0xFF0C9A82);
  static const coral = Color(0xFFFF6B6B);
  static const amber = Color(0xFFFFC145);
  static const amberLight = Color(0xFFFFE3A0);
  static const violet = Color(0xFF8B6CFF);
  static const sky = Color(0xFF4DA8FF);
  static const slate = Color(0xFF59607A);
}

TextStyle gameText(double size, {Color color = Colors.white, double weight = 800, Color? shadowColor}) {
  return TextStyle(
    fontFamily: kGameFont,
    fontSize: size,
    color: color,
    height: 1.1,
    fontWeight: FontWeight.values[(weight / 100).round().clamp(1, 9) - 1],
    fontVariations: [FontVariation('wght', weight)],
    shadows: shadowColor == null ? null : [Shadow(color: shadowColor, offset: Offset(0, size / 14))],
  );
}

/// Bold rounded text with a soft "sticker" drop shadow.
class GameText extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  final Color? shadow;
  final double weight;
  final TextAlign textAlign;

  const GameText(
    this.text, {
    super.key,
    this.size = 24,
    this.color = Colors.white,
    this.shadow = const Color(0x66000000),
    this.weight = 800,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Text(text, textAlign: textAlign, style: gameText(size, color: color, weight: weight, shadowColor: shadow));
  }
}

Path starPath(Offset c, double outer, double inner, {int points = 5, double rotation = -math.pi / 2}) {
  final path = Path();
  for (var i = 0; i < points * 2; i++) {
    final r = i.isEven ? outer : inner;
    final a = rotation + i * math.pi / points;
    final p = c + Offset(math.cos(a), math.sin(a)) * r;
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  return path..close();
}

/// Indigo gradient with a scatter of tiny stars.
class GameBackground extends StatelessWidget {
  final Widget child;
  const GameBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [GameColors.night1, GameColors.night0]),
      ),
      child: CustomPaint(painter: _SparklePainter(), child: SizedBox.expand(child: child)),
    );
  }
}

class _SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(11);
    for (var i = 0; i < 46; i++) {
      final p = Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height);
      final alpha = 0.10 + rng.nextDouble() * 0.30;
      final paint = Paint()..color = Colors.white.withValues(alpha: alpha);
      if (i % 5 == 0) {
        canvas.drawPath(starPath(p, 5 + rng.nextDouble() * 4, 1.6, points: 4), paint);
      } else {
        canvas.drawCircle(p, 0.8 + rng.nextDouble() * 1.6, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Frosted-glass surface.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 28});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: GameColors.glass,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: GameColors.glassBorder),
      ),
      child: child,
    );
  }
}

/// Rounded button with a darker base that presses down on tap.
class ChunkyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color color;
  final Color baseColor;
  final double height;
  final double? width;

  const ChunkyButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color = GameColors.mint,
    this.baseColor = GameColors.mintDark,
    this.height = 72,
    this.width,
  });

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const lip = 6.0;
    final enabled = widget.onPressed != null;
    final color = enabled ? widget.color : const Color(0xFF6C6F86);
    final base = enabled ? widget.baseColor : const Color(0xFF474A5E);
    final radius = BorderRadius.circular(widget.height / 2.6);

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: SizedBox(
        width: widget.width,
        height: widget.height + lip,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: widget.height,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                decoration: BoxDecoration(color: base, borderRadius: radius),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              left: 0,
              right: 0,
              top: _pressed ? lip - 3 : 0,
              height: widget.height,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color.lerp(color, Colors.white, 0.22)!, color],
                  ),
                  boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 6))],
                ),
                child: Center(child: widget.child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
