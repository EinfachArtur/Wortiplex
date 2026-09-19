import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/economy_config.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/game_style.dart';
import '../../domain/models/game_mode.dart';
import '../../domain/models/letter_state.dart';
import '../../domain/models/round.dart';
import 'coin_icon.dart';

/// End-of-round dialog: confetti on a win, the solution word, attempts,
/// streak and coin reward, plus copying the emoji result grid.
class GameResultDialog extends StatefulWidget {
  final Round round;
  final int streak;
  final int? coinsWon;
  final VoidCallback onNextRound;
  final VoidCallback? onHome;

  const GameResultDialog({
    super.key,
    required this.round,
    required this.streak,
    this.coinsWon,
    required this.onNextRound,
    this.onHome,
  });

  static Future<void> show(
    BuildContext context, {
    required Round round,
    required int streak,
    int? coinsWon,
    required VoidCallback onNextRound,
    VoidCallback? onHome,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'GameResult',
      barrierColor: const Color(0xFF0B0724).withValues(alpha: 0.78),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, _, _) => GameResultDialog(
        round: round,
        streak: streak,
        coinsWon: coinsWon,
        onNextRound: onNextRound,
        onHome: onHome,
      ),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(scale: curved, child: FadeTransition(opacity: anim, child: child));
      },
    );
  }

  @override
  State<GameResultDialog> createState() => _GameResultDialogState();
}

class _GameResultDialogState extends State<GameResultDialog> with TickerProviderStateMixin {
  late final AnimationController _confetti = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  late final AnimationController _letters = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  final List<_Particle> _particles = [];

  bool get _won => widget.round.result == RoundResult.won;
  bool get _isDaily => widget.round.mode == GameMode.daily;

  @override
  void initState() {
    super.initState();
    if (_won) {
      final rng = math.Random();
      const colors = [GameColors.mint, GameColors.amber, GameColors.coral, GameColors.violet, GameColors.sky, Colors.white];
      for (var i = 0; i < 60; i++) {
        _particles.add(_Particle(
          x: rng.nextDouble(),
          delay: rng.nextDouble() * 0.5,
          speed: 0.5 + rng.nextDouble() * 0.6,
          drift: (rng.nextDouble() - 0.5) * 0.25,
          size: 6 + rng.nextDouble() * 7,
          spin: (rng.nextDouble() - 0.5) * 8,
          color: colors[rng.nextInt(colors.length)],
          round: rng.nextBool(),
        ));
      }
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    _letters.dispose();
    super.dispose();
  }

  void _copyResult(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final buffer = StringBuffer('WortiPlex ${widget.round.guesses.length}/${widget.round.maxAttempts}\n\n');
    for (final guess in widget.round.guesses) {
      for (final letter in guess.evaluation) {
        buffer.write(switch (letter.state) {
          LetterState.correct => '🟩',
          LetterState.present => '🟨',
          _ => '⬛',
        });
      }
      buffer.writeln();
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.copiedToClipboard), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accent = _won ? GameColors.amber : GameColors.coral;
    final coins = widget.coinsWon ?? EconomyConfig.roundCompletionReward;
    final word = widget.round.solutionWord;

    return Stack(
      children: [
        if (_won)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confetti,
                builder: (_, _) => CustomPaint(painter: _ConfettiPainter(_particles, _confetti.value)),
              ),
            ),
          ),
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 330,
              margin: const EdgeInsets.symmetric(vertical: 24),
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3B2A8C), Color(0xFF221860)]),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: accent, width: 2.5),
                boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 40)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _won ? const [GameColors.amberLight, GameColors.amber] : const [Color(0xFFFF9A9A), GameColors.coral],
                      ),
                      boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.6), blurRadius: 24)],
                    ),
                    child: Icon(_won ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded, color: GameColors.night0, size: 48),
                  ),
                  const SizedBox(height: 14),
                  GameText(_won ? l10n.resultWon : l10n.resultLost, size: 32, color: accent),
                  const SizedBox(height: 4),
                  GameText(_won ? l10n.resultWonSub : l10n.resultLostSub, size: 14, color: GameColors.textDim, shadow: null, weight: 500),
                  const SizedBox(height: 18),
                  GameText(l10n.solutionLabel.toUpperCase(), size: 11, color: GameColors.textDim, shadow: null, weight: 700),
                  const SizedBox(height: 8),
                  _SolutionRow(word: word, animation: _letters, color: _won ? AppColors.correct : GameColors.coral),
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Stat(icon: Icons.track_changes_rounded, color: GameColors.sky, value: '${widget.round.guesses.length}/${widget.round.maxAttempts}', label: l10n.attemptsLabel),
                      _Stat(icon: Icons.local_fire_department_rounded, color: GameColors.amber, value: '${widget.streak}', label: l10n.streakLabel),
                      if (_won && (widget.coinsWon == null || widget.coinsWon! > 0))
                        _Stat(coin: true, value: '+$coins', label: l10n.coins),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ChunkyButton(
                        height: 56,
                        width: 58,
                        color: const Color(0xFF4A3A94),
                        baseColor: const Color(0xFF2E2068),
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (widget.onHome != null) {
                            widget.onHome!();
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Icon(Icons.home_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChunkyButton(
                          height: 56,
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onNextRound();
                          },
                          child: GameText(_isDaily ? l10n.ok : l10n.newGame, size: 20, color: GameColors.night0, shadow: null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: () => _copyResult(context),
                    icon: const Icon(Icons.ios_share_rounded, size: 18, color: GameColors.textDim),
                    label: GameText(l10n.shareResult, size: 14, color: GameColors.textDim, shadow: null, weight: 600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SolutionRow extends StatelessWidget {
  final String word;
  final Animation<double> animation;
  final Color color;
  const _SolutionRow({required this.word, required this.animation, required this.color});

  @override
  Widget build(BuildContext context) {
    final letters = word.split('');
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < letters.length; i++)
            Builder(builder: (context) {
              final start = i / (letters.length + 1);
              final t = Curves.easeOutBack.transform(((animation.value - start) / 0.4).clamp(0.0, 1.0));
              return Transform.scale(
                scale: t,
                child: Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: GameText(letters[i], size: 24, shadow: null),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData? icon;
  final Color? color;
  final bool coin;
  final String value;
  final String label;

  const _Stat({this.icon, this.color, this.coin = false, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: GameColors.glass, borderRadius: BorderRadius.circular(18), border: Border.all(color: GameColors.glassBorder)),
      child: Column(
        children: [
          coin ? const CoinIcon(size: 24) : Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          GameText(value, size: 18, shadow: null),
          GameText(label, size: 11, color: GameColors.textDim, shadow: null, weight: 500),
        ],
      ),
    );
  }
}

class _Particle {
  final double x, delay, speed, drift, size, spin;
  final Color color;
  final bool round;
  const _Particle({
    required this.x,
    required this.delay,
    required this.speed,
    required this.drift,
    required this.size,
    required this.spin,
    required this.color,
    required this.round,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  _ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress + p.delay) % 1.0;
      final y = -20 + (size.height + 40) * (t * p.speed).clamp(0.0, 1.0);
      final x = size.width * (p.x + p.drift * t);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t * math.pi);
      final paint = Paint()..color = p.color.withValues(alpha: 0.9);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55), const Radius.circular(2)), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.progress != progress;
}
