import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/game_style.dart';
import '../../domain/models/game_mode.dart';
import '../../domain/models/letter_state.dart';
import '../../domain/models/round.dart';

const _flipStagger = Duration(milliseconds: 260);
const _flipDuration = Duration(milliseconds: 480);

class TileGrid extends StatefulWidget {
  final Round round;
  final List<String> currentLetters;
  final int cursorIndex;
  final ValueChanged<int>? onTileTap;

  /// Increment to make the current row shake (e.g. for an invalid word).
  final int shakeCount;

  const TileGrid({
    super.key,
    required this.round,
    required this.currentLetters,
    this.cursorIndex = 0,
    this.onTileTap,
    this.shakeCount = 0,
  });

  /// How long the reveal flip of a whole row takes.
  static Duration revealDuration(int wordLength) => _flipStagger * (wordLength - 1) + _flipDuration;

  /// Extra time the win wave needs after the flip has finished.
  static const winWaveDuration = Duration(milliseconds: 750);

  @override
  State<TileGrid> createState() => _TileGridState();
}

class _TileGridState extends State<TileGrid> with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 460));

  @override
  void didUpdateWidget(covariant TileGrid old) {
    super.didUpdateWidget(old);
    if (widget.shakeCount != old.shakeCount) _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final round = widget.round;
    final wordLength = round.solutionWord.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < round.maxAttempts; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            // Every row has the same widget structure. Otherwise a row that changes
            // from "current" to "guessed" would be rebuilt from scratch and its
            // tiles would lose their state (and skip the reveal flip).
            child: AnimatedBuilder(
              animation: _shake,
              builder: (context, child) {
                final t = _shake.value;
                // Damped side-to-side wobble, only for the row being typed.
                final dx = row == round.guesses.length ? math.sin(t * math.pi * 7) * 10 * (1 - t) : 0.0;
                return Transform.translate(offset: Offset(dx, 0), child: child);
              },
              child: _buildRow(row, wordLength),
            ),
          ),
      ],
    );
  }

  Widget _buildRow(int row, int wordLength) {
    final round = widget.round;
    final isPastGuess = row < round.guesses.length;
    final isCurrentRow = row == round.guesses.length;
    final winningRow = round.result == RoundResult.won && row == round.guesses.length - 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var col = 0; col < wordLength; col++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.5),
            child: _Tile(
              key: ValueKey('tile_${row}_$col'),
              letter: isPastGuess
                  ? round.guesses[row].evaluation[col].letter
                  : (isCurrentRow && col < widget.currentLetters.length ? widget.currentLetters[col] : ''),
              state: isPastGuess ? round.guesses[row].evaluation[col].state : LetterState.unknown,
              flipDelay: _flipStagger * col,
              winWave: winningRow,
              isSelected: isCurrentRow && !round.isFinished && col == widget.cursorIndex,
              onTap: isCurrentRow && !round.isFinished ? () => widget.onTileTap?.call(col) : null,
            ),
          ),
      ],
    );
  }
}

/// A letter tile with three animations: a springy "pop" when a letter is
/// typed, a staggered 3D flip when its row is evaluated, and a small hop
/// (also staggered) when the row is the winning one.
class _Tile extends StatefulWidget {
  final String letter;
  final LetterState state;
  final Duration flipDelay;
  final bool winWave;
  final bool isSelected;
  final VoidCallback? onTap;

  const _Tile({
    super.key,
    required this.letter,
    required this.state,
    required this.flipDelay,
    this.winWave = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> with TickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(vsync: this, duration: _flipDuration);
  late final AnimationController _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 240));
  late final AnimationController _hop = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
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

    // A letter was typed (or replaced): let the tile pop.
    if (widget.state == LetterState.unknown && widget.letter.isNotEmpty && widget.letter != old.letter) {
      _pop.forward(from: 0);
    }

    if (!old.winWave && widget.winWave) {
      Future.delayed(widget.flipDelay + _flipDuration + const Duration(milliseconds: 80), () {
        if (mounted) _hop.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    _pop.dispose();
    _hop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_flip, _pop, _hop]),
      builder: (context, _) {
        final t = _flip.value;
        final flipping = _flip.isAnimating;
        // Show the old face during the first half of the flip, the new one after.
        final shown = flipping && t < 0.5 ? _before : widget.state;
        final angle = t < 0.5 ? t * math.pi : (t - 1) * math.pi;

        final popScale = _pop.isAnimating ? 0.86 + 0.14 * Curves.easeOutBack.transform(_pop.value) : 1.0;
        final hopY = _hop.isAnimating ? -16 * math.sin(_hop.value * math.pi) : 0.0;

        return Transform.translate(
          offset: Offset(0, hopY),
          child: Transform.scale(
            scale: popScale,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002)
                ..rotateX(flipping ? angle : 0),
              child: _face(shown),
            ),
          ),
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

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(14),
          border: evaluated
              ? null
              : Border.all(
                  color: widget.isSelected ? GameColors.mint : (hasLetter ? Colors.white70 : AppColors.tileBorder),
                  width: widget.isSelected ? 2.5 : 2,
                ),
          boxShadow: evaluated && state != LetterState.absent
              ? [BoxShadow(color: fill.withValues(alpha: 0.45), blurRadius: 10, offset: const Offset(0, 3))]
              : (widget.isSelected ? [BoxShadow(color: GameColors.mint.withValues(alpha: 0.55), blurRadius: 12)] : null),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 90),
          child: Text(widget.letter, key: ValueKey(widget.letter), style: gameText(28, color: textColor, weight: 800)),
        ),
      ),
    );
  }
}
