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

  /// Column indices (0-based) after which a wider gap is inserted, e.g. to
  /// separate DD | MM | YYYY groups in date-guess mode.
  final Set<int> groupBreaksAfter;

  /// Tile size and font size, so a mode with fewer/narrower columns (like
  /// date-guess) can size its tiles up instead of leaving the board small.
  final double tileSize;
  final double tileFontSize;

  /// Tile height, when a mode wants tall rather than square tiles (e.g. 8
  /// narrow date-guess columns, where width is tight but height is not).
  /// Defaults to [tileSize] (a square tile).
  final double? tileHeight;

  const TileGrid({
    super.key,
    required this.round,
    required this.currentLetters,
    this.cursorIndex = 0,
    this.onTileTap,
    this.shakeCount = 0,
    this.groupBreaksAfter = const {},
    this.tileSize = 56.0,
    this.tileFontSize = 28.0,
    this.tileHeight,
  });

  /// Stagger delay between sequential letter reveals.
  static Duration get flipStagger => _flipStagger;

  /// Duration for a single letter's 3D card flip.
  static Duration get flipDuration => _flipDuration;

  /// How long the reveal flip of a whole row takes.
  static Duration revealDuration(int wordLength) => _flipStagger * (wordLength - 1) + _flipDuration;

  /// Extra time the win wave needs after the flip has finished.
  static const winWaveDuration = Duration(milliseconds: 800);

  /// Horizontal gap on either side of a tile, and the wider gap used after a
  /// [groupBreaksAfter] column. Exposed so a caller can size tiles to exactly
  /// fill the width it has available (see date-guess mode).
  static const tileGap = 3.5;
  static const groupGap = 14.0;

  /// Total horizontal space the gaps around [columns] tiles take up, [breaksAfter]
  /// of them wider group breaks.
  static double horizontalGapsFor(int columns, Set<int> breaksAfter) {
    var total = columns * tileGap; // every tile's left gap
    for (var col = 0; col < columns; col++) {
      total += breaksAfter.contains(col) ? groupGap : tileGap; // that tile's right gap
    }
    return total;
  }

  /// Total vertical space one row's padding takes up.
  static const rowVerticalPadding = 8.0; // 4 top + 4 bottom

  @override
  State<TileGrid> createState() => _TileGridState();
}

class _TileGridState extends State<TileGrid> with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

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
            padding: const EdgeInsets.symmetric(vertical: TileGrid.rowVerticalPadding / 2),
            // Every row maintains the same widget tree structure so that when a row
            // transitions from current to guessed, its tiles preserve state for the flip.
            child: AnimatedBuilder(
              animation: _shake,
              builder: (context, child) {
                final t = _shake.value;
                // Damped sinusoidal horizontal shake for the active row.
                final dx = row == round.guesses.length ? math.sin(t * math.pi * 8) * 12.0 * (1.0 - t) : 0.0;
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
            padding: EdgeInsets.only(
              left: TileGrid.tileGap,
              right: widget.groupBreaksAfter.contains(col) ? TileGrid.groupGap : TileGrid.tileGap,
            ),
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
              size: widget.tileSize,
              height: widget.tileHeight,
              fontSize: widget.tileFontSize,
            ),
          ),
      ],
    );
  }
}
