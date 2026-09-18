import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/game_style.dart';
import '../../domain/models/letter_state.dart';
import '../../domain/models/round.dart';

class TileGrid extends StatelessWidget {
  final Round round;
  final String currentInput;

  const TileGrid({super.key, required this.round, required this.currentInput});

  @override
  Widget build(BuildContext context) {
    final wordLength = round.solutionWord.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < round.maxAttempts; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _buildRow(row, wordLength),
          ),
      ],
    );
  }

  Widget _buildRow(int row, int wordLength) {
    final isPastGuess = row < round.guesses.length;
    final isCurrentRow = row == round.guesses.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var col = 0; col < wordLength; col++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.5),
            child: _Tile(
              letter: isPastGuess
                  ? round.guesses[row].evaluation[col].letter
                  : (isCurrentRow && col < currentInput.length ? currentInput[col] : ''),
              state: isPastGuess ? round.guesses[row].evaluation[col].state : LetterState.unknown,
              flipDelay: Duration(milliseconds: 260 * col),
            ),
          ),
      ],
    );
  }
}

/// A letter tile. When its state changes from "unknown" to an evaluated state
/// it flips over (staggered by column) to reveal the colour.
class _Tile extends StatefulWidget {
  final String letter;
  final LetterState state;
  final Duration flipDelay;

  const _Tile({required this.letter, required this.state, required this.flipDelay});

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
  LetterState _before = LetterState.unknown;

  @override
  void didUpdateWidget(covariant _Tile old) {
    super.didUpdateWidget(old);
    if (old.state == LetterState.unknown && widget.state != LetterState.unknown) {
      _before = LetterState.unknown;
      Future.delayed(widget.flipDelay, () {
        if (mounted) _flip.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flip,
      builder: (context, _) {
        final t = _flip.value;
        final flipping = _flip.isAnimating;
        // Show the old face during the first half of the flip, the new one after.
        final shown = flipping && t < 0.5 ? _before : widget.state;
        final angle = t < 0.5 ? t * math.pi : (t - 1) * math.pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateX(flipping ? angle : 0),
          child: _face(shown),
        );
      },
    );
  }

  Widget _face(LetterState state) {
    final evaluated = state != LetterState.unknown;
    final Color fill = switch (state) {
      LetterState.correct => AppColors.correct,
      LetterState.present => AppColors.present,
      LetterState.absent => AppColors.absent,
      LetterState.unknown => AppColors.tileEmpty,
    };
    final Color textColor = switch (state) {
      LetterState.present => GameColors.night0,
      LetterState.absent => Colors.white70,
      _ => Colors.white,
    };
    final hasLetter = widget.letter.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 56,
      height: 56,
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(!evaluated && hasLetter ? 1.06 : 1.0, !evaluated && hasLetter ? 1.06 : 1.0, 1.0),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: evaluated ? null : Border.all(color: hasLetter ? Colors.white70 : AppColors.tileBorder, width: 2),
        boxShadow: evaluated && state != LetterState.absent
            ? [BoxShadow(color: fill.withValues(alpha: 0.45), blurRadius: 10, offset: const Offset(0, 3))]
            : null,
      ),
      child: Text(widget.letter, style: gameText(28, color: textColor, weight: 800)),
    );
  }
}
