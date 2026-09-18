import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/game_mode.dart';
import '../../domain/models/letter_state.dart';
import '../../domain/models/round.dart';

/// A playful, high-energy result dialog featuring custom particle/confetti
/// animations, 3D tile flips, glowing gradients, streak badges, and share options.
class GameResultDialog extends StatefulWidget {
  final Round round;
  final int streak;
  final int? coinsWon;
  final VoidCallback onNextRound;

  const GameResultDialog({
    super.key,
    required this.round,
    required this.streak,
    this.coinsWon,
    required this.onNextRound,
  });

  static Future<void> show(
    BuildContext context, {
    required Round round,
    required int streak,
    int? coinsWon,
    required VoidCallback onNextRound,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'GameResult',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => GameResultDialog(
        round: round,
        streak: streak,
        coinsWon: coinsWon,
        onNextRound: onNextRound,
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
  State<GameResultDialog> createState() => _GameResultDialogState();
}

class _GameResultDialogState extends State<GameResultDialog>
    with TickerProviderStateMixin {
  late final AnimationController _confettiController;
  late final AnimationController _badgeController;
  late final AnimationController _tilesController;
  final List<_ConfettiParticle> _particles = [];

  bool get _won => widget.round.result == RoundResult.won;
  bool get _isDaily => widget.round.mode == GameMode.daily;

  @override
  void initState() {
    super.initState();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _tilesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    if (_won) {
      _initConfetti();
    }
  }

  void _initConfetti() {
    final rng = math.Random();
    const colors = [
      Color(0xFFFF5252),
      Color(0xFFFFD700),
      Color(0xFF4CAF50),
      Color(0xFF2196F3),
      Color(0xFFE040FB),
      Color(0xFFFF9800),
      Color(0xFF00E5FF),
    ];
    for (int i = 0; i < 65; i++) {
      _particles.add(
        _ConfettiParticle(
          x: rng.nextDouble(),
          y: -rng.nextDouble() * 0.4,
          vx: (rng.nextDouble() - 0.5) * 0.4,
          vy: 0.3 + rng.nextDouble() * 0.5,
          size: 6 + rng.nextDouble() * 8,
          rotation: rng.nextDouble() * math.pi * 2,
          rotationSpeed: (rng.nextDouble() - 0.5) * 6,
          color: colors[rng.nextInt(colors.length)],
          isCircle: rng.nextBool(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _badgeController.dispose();
    _tilesController.dispose();
    super.dispose();
  }

  void _shareResult(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln('Wortiplex ${_won ? "🏆" : "💔"} (${widget.round.guesses.length}/${widget.round.maxAttempts})');
    buffer.writeln();

    for (final guess in widget.round.guesses) {
      for (final letter in guess.evaluation) {
        switch (letter.state) {
          case LetterState.correct:
            buffer.write('🟩');
            break;
          case LetterState.present:
            buffer.write('🟨');
            break;
          case LetterState.absent:
          case LetterState.unknown:
            buffer.write('⬛');
            break;
        }
      }
      buffer.writeln();
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text('Ergebnis in die Zwischenablage kopiert! 🎉'),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // Animated Confetti overlay if won
        if (_won)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ConfettiPainter(particles: _particles, progress: _confettiController.value),
                  );
                },
              ),
            ),
          ),

        // Main Dialog Card
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF1E222B), const Color(0xFF15181F)]
                        : [Colors.white, const Color(0xFFF7F9FC)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: _won
                        ? AppColors.correct.withValues(alpha: 0.6)
                        : Colors.redAccent.withValues(alpha: 0.4),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_won ? AppColors.correct : Colors.redAccent)
                          .withValues(alpha: 0.25),
                      blurRadius: 30,
                      spreadRadius: 4,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Playful animated Header Badge
                      _buildHeaderBadge(),

                      const SizedBox(height: 14),

                      // Title
                      Text(
                        _won
                            ? (widget.round.guesses.length == 1
                                ? 'GENIAL! 🤯'
                                : widget.round.guesses.length <= 3
                                    ? 'SUPER GEMACHT! 🌟'
                                    : l10n.youWon)
                            : 'SCHADE! 💔',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: _won ? AppColors.correct : Colors.redAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 6),

                      Text(
                        _won
                            ? 'Du hast das Wort geknackt!'
                            : 'Keine Versuche mehr übrig.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Animated Word Reveal Tiles
                      _buildSolutionTiles(),

                      const SizedBox(height: 20),

                      // Stats & Reward summary badges
                      _buildStatsRow(isDark),

                      const SizedBox(height: 26),

                      // Playful Action Buttons
                      _buildActionButtons(l10n),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderBadge() {
    return ScaleTransition(
      scale: TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.25).chain(CurveTween(curve: Curves.easeOutBack)), weight: 70),
        TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
      ]).animate(_badgeController),
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: _won
                ? [const Color(0xFFFFD700), const Color(0xFFFF8F00)]
                : [const Color(0xFFFF5252), const Color(0xFFC62828)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: (_won ? const Color(0xFFFFD700) : const Color(0xFFFF5252))
                  .withValues(alpha: 0.4),
              blurRadius: 18,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          _won ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSolutionTiles() {
    final word = widget.round.solutionWord;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _won
            ? AppColors.correct.withValues(alpha: 0.12)
            : Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _won
              ? AppColors.correct.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            'LÖSUNGSWORT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: _won ? AppColors.correct : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < word.length; i++)
                _buildSingleTile(word[i], i, word.length),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSingleTile(String char, int index, int total) {
    return AnimatedBuilder(
      animation: _tilesController,
      builder: (context, child) {
        final delay = index / total * 0.5;
        final animValue = ((_tilesController.value - delay) / 0.5).clamp(0.0, 1.0);
        final curved = Curves.elasticOut.transform(animValue);

        return Transform.scale(
          scale: curved,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 44,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _won
                    ? [const Color(0xFF76C86F), AppColors.correct]
                    : [const Color(0xFF616161), const Color(0xFF424242)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: (_won ? AppColors.correct : Colors.black45).withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              char,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Attempts Badge
        _buildStatPill(
          icon: Icons.track_changes,
          iconColor: Colors.blueAccent,
          label: '${widget.round.guesses.length}/${widget.round.maxAttempts}',
          subtitle: 'Versuche',
          isDark: isDark,
        ),
        const SizedBox(width: 8),

        // Streak Badge
        _buildStatPill(
          icon: Icons.local_fire_department_rounded,
          iconColor: Colors.orangeAccent,
          label: '${widget.streak}',
          subtitle: 'Streak',
          isDark: isDark,
        ),

        // Coins gained (if any)
        if (widget.coinsWon != null && widget.coinsWon! > 0) ...[
          const SizedBox(width: 8),
          _buildStatPill(
            icon: Icons.monetization_on_rounded,
            iconColor: AppColors.coinGold,
            label: '+${widget.coinsWon}',
            subtitle: 'Münzen',
            isDark: isDark,
          ),
        ],
      ],
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2E39) : const Color(0xFFEEF2F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white54 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    return Column(
      children: [
        // Primary Bouncy Gradient Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _won
                    ? [const Color(0xFF76C86F), AppColors.correct]
                    : [const Color(0xFF42A5F5), const Color(0xFF1E88E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (_won ? AppColors.correct : Colors.blue).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
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
              onPressed: () {
                Navigator.of(context).pop();
                widget.onNextRound();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isDaily ? Icons.check_circle_outline : Icons.play_arrow_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    _isDaily ? 'OK' : l10n.newGame.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Share button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.grey, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _shareResult(context),
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text(
              'Ergebnis teilen',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double rotation;
  double rotationSpeed;
  Color color;
  bool isCircle;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final curY = ((p.y + p.vy * progress * 4.0) % 1.2) * size.height;
      final curX = (p.x + p.vx * math.sin(progress * math.pi * 2 + p.rotation)) * size.width;
      final curRotation = p.rotation + p.rotationSpeed * progress * math.pi * 2;

      canvas.save();
      canvas.translate(curX, curY);
      canvas.rotate(curRotation);

      final paint = Paint()
        ..color = p.color.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
