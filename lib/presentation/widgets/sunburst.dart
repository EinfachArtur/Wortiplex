import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Slowly rotating light rays, used behind won prizes.
class Sunburst extends StatefulWidget {
  final double size;
  final Color color;
  const Sunburst({super.key, this.size = 420, this.color = Colors.white});

  @override
  State<Sunburst> createState() => _SunburstState();
}

class _SunburstState extends State<Sunburst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Transform.rotate(
        angle: _c.value * 2 * math.pi,
        child: CustomPaint(size: Size.square(widget.size), painter: _RaysPainter(widget.color)),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  final Color color;
  _RaysPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    const rays = 14;
    final shader = RadialGradient(colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0)])
        .createShader(Rect.fromCircle(center: c, radius: r));
    final paint = Paint()..shader = shader;
    for (var i = 0; i < rays; i++) {
      final a = i * 2 * math.pi / rays;
      final w = math.pi / rays * 0.8;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + r * math.cos(a - w / 2), c.dy + r * math.sin(a - w / 2))
        ..lineTo(c.dx + r * math.cos(a + w / 2), c.dy + r * math.sin(a + w / 2))
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RaysPainter old) => old.color != color;
}
