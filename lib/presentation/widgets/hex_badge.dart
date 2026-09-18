import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/game_style.dart';

enum BadgeState { locked, claimable, claimed, earned }

/// Hexagon reward badge in a tier colour. Locked badges are dim, claimable
/// ones glow, claimed ones carry a check mark.
class HexBadge extends StatelessWidget {
  final List<Color> colors;
  final BadgeState state;
  final double size;

  const HexBadge({super.key, required this.colors, required this.state, this.size = 72});

  @override
  Widget build(BuildContext context) {
    final locked = state == BadgeState.locked;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: Size.square(size), painter: _HexPainter(colors, state)),
          Icon(
            locked ? Icons.lock_rounded : (state == BadgeState.claimed ? Icons.check_rounded : Icons.workspace_premium_rounded),
            size: size * 0.44,
            color: locked ? const Color(0x88FFFFFF) : Colors.white,
            shadows: locked ? null : const [Shadow(color: Color(0x55000000), offset: Offset(0, 2))],
          ),
        ],
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  final List<Color> colors;
  final BadgeState state;
  _HexPainter(this.colors, this.state);

  Path _hex(Offset c, double r) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final a = math.pi / 6 + i * math.pi / 3; // pointy-top
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.46;
    final path = _hex(c, r);

    if (state == BadgeState.locked) {
      canvas.drawPath(path, Paint()..color = const Color(0x26FFFFFF));
      canvas.drawPath(path, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0x40FFFFFF));
      return;
    }

    if (state == BadgeState.claimable) {
      canvas.drawPath(path, Paint()
        ..color = GameColors.amber.withValues(alpha: 0.75)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    } else {
      canvas.drawPath(path.shift(const Offset(0, 3)), Paint()..color = const Color(0x40000000));
    }
    canvas.drawPath(
      path,
      Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors).createShader(Offset.zero & size),
    );
    canvas.drawPath(_hex(c, r * 0.8), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0x66FFFFFF));
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(covariant _HexPainter old) => old.state != state || old.colors != colors;
}
