import 'package:flutter/material.dart';

const kGameFont = 'LilitaOne';

/// Colours of the playful "game" look used by the wheel and puzzle screens.
class GameColors {
  const GameColors._();

  static const background = Color(0xFF454545);
  static const backgroundStripe = Color(0xFF4B4B4B);
  static const pill = Color(0xFF2E2E2E);
  static const panel = Color(0xFF8E8E8E);
  static const panelLight = Color(0xFFA8A8A8);
  static const green = Color(0xFF5FD62E);
  static const greenDark = Color(0xFF3C9E1B);
  static const orange = Color(0xFFF7823C);
  static const orangeDark = Color(0xFFC25A1E);
  static const purple = Color(0xFF8422BE);
  static const blueDay = Color(0xFF8FD8F5);
  static const missedRed = Color(0xFFE81414);
  static const gold = Color(0xFFF5B301);
  static const goldLight = Color(0xFFFFE07A);
}

/// Dark background with soft diagonal stripes.
class GameBackground extends StatelessWidget {
  final Widget child;
  const GameBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StripePainter(),
      child: SizedBox.expand(child: child),
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = GameColors.background);
    final paint = Paint()
      ..color = GameColors.backgroundStripe
      ..strokeWidth = 26;
    const gap = 74.0;
    for (var x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Big rounded button with a darker "base" underneath that is pressed down
/// on tap, like the buttons in the reference design.
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
    this.color = GameColors.green,
    this.baseColor = GameColors.greenDark,
    this.height = 84,
    this.width,
  });

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const lip = 7.0;
    final enabled = widget.onPressed != null;
    final color = enabled ? widget.color : Colors.grey.shade500;
    final base = enabled ? widget.baseColor : Colors.grey.shade700;

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
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(widget.height / 2),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              left: 0,
              right: 0,
              top: _pressed ? lip - 3 : 0,
              height: widget.height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(widget.height / 2),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 6))],
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

/// Chunky game text with a dark outline.
class OutlinedText extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  final Color outline;
  final TextAlign textAlign;

  const OutlinedText(
    this.text, {
    super.key,
    this.size = 28,
    this.color = Colors.white,
    this.outline = const Color(0xFF2A2A2A),
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontFamily: kGameFont, fontSize: size, height: 1.05);
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          textAlign: textAlign,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size / 6
              ..strokeJoin = StrokeJoin.round
              ..color = outline,
          ),
        ),
        Text(text, textAlign: textAlign, style: base.copyWith(color: color)),
      ],
    );
  }
}
