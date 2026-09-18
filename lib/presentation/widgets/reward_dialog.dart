import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A playful reward popup overlay for daily logins and spin wheel wins.
class RewardCelebrationDialog extends StatefulWidget {
  final int coins;
  final String title;
  final String message;
  final IconData icon;

  const RewardCelebrationDialog({
    super.key,
    required this.coins,
    required this.title,
    required this.message,
    this.icon = Icons.casino,
  });

  static Future<void> show(
    BuildContext context, {
    required int coins,
    required String title,
    required String message,
    IconData icon = Icons.casino,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'RewardCelebration',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => RewardCelebrationDialog(
        coins: coins,
        title: title,
        message: message,
        icon: icon,
      ),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }

  @override
  State<RewardCelebrationDialog> createState() => _RewardCelebrationDialogState();
}

class _RewardCelebrationDialogState extends State<RewardCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotController;

  @override
  void initState() {
    super.initState();
    _rotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _rotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF26231C), const Color(0xFF191814)]
                    : [Colors.white, const Color(0xFFFFFBF0)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.coinGold.withValues(alpha: 0.7),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.coinGold.withValues(alpha: 0.3),
                  blurRadius: 28,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Rotating sunburst glow behind coin
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _rotController,
                          builder: (_, __) => Transform.rotate(
                            angle: _rotController.value * math.pi * 2,
                            child: CustomPaint(
                              size: const Size(100, 100),
                              painter: _SunburstPainter(),
                            ),
                          ),
                        ),
                        Container(
                          width: 68,
                          height: 68,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFFFFD54F), AppColors.coinGold],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x66FFB300),
                                blurRadius: 14,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.monetization_on_rounded,
                            size: 42,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.coinGold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 6),

                  Text(
                    widget.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Big coin reward badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.coinGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.coinGold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, color: AppColors.coinGold, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          '+${widget.coins} MÜNZEN',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: AppColors.coinGold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Claim button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD54F), AppColors.coinGold],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.coinGold.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'EINSAMMELN! 🎉',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SunburstPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const count = 12;
    final paint = Paint()
      ..color = const Color(0x33FFD54F)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final startAngle = i * (2 * math.pi / count);
      const sweepAngle = math.pi / count;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
