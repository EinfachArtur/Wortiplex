import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/game_mode.dart';
import '../../domain/models/letter_state.dart';
import '../../domain/models/round.dart';
import 'animated_wordle_tile.dart';

const _flipStagger = Duration(milliseconds: 250);
const _flipDuration = Duration(milliseconds: 500);

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

  /// Stagger delay between sequential letter reveals.
  static Duration get flipStagger => _flipStagger;

  /// Duration for a single letter's 3D card flip.
  static Duration get flipDuration => _flipDuration;

  /// How long the reveal flip of a whole row takes.
  static Duration revealDuration(int wordLength) => _flipStagger * (wordLength - 1) + _flipDuration;

  /// Extra time the win wave needs after the flip has finished.
  static const winWaveDuration = Duration(milliseconds: 800);

  @override
  State<TileGrid> createState() => _TileGridState();
}

class _TileGridState extends State<TileGrid> with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void didUpdateWidget(covariant TileGrid old) {
    super.didUpdateWidget(old);
    if (widget.shakeCount != old.shakeCount) {
      _shake.forward(from: 0.0);
    }
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
            // Every row maintains the same widget tree structure so that when a row
            // transitions from current to guessed, its tiles preserve state for the flip.
            child: AnimatedBuilder(
              animation: _shake,
              builder: (context, child) {
                final t = _shake.value;
                // Damped sinusoidal horizontal shake for the active row.
                final dx = row == round.guesses.length
                    ? math.sin(t * math.pi * 8) * 12.0 * (1.0 - t)
                    : 0.0;
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
            child: AnimatedWordleTile(
              key: ValueKey('tile_${row}_$col'),
              letter: isPastGuess
                  ? round.guesses[row].evaluation[col].letter
                  : (isCurrentRow && col < widget.currentLetters.length ? widget.currentLetters[col] : ''),
              state: isPastGuess ? round.guesses[row].evaluation[col].state : LetterState.unknown,
              flipDelay: _flipStagger * col,
              flipDuration: _flipDuration,
              winWave: winningRow,
              isSelected: isCurrentRow && !round.isFinished && col == widget.cursorIndex,
              onTap: isCurrentRow && !round.isFinished ? () => widget.onTileTap?.call(col) : null,
            ),
          ),
      ],
    );
  }
}
